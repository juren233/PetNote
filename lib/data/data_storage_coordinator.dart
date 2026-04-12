import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:petnote/data/data_storage_models.dart';
import 'package:petnote/logging/app_log_controller.dart';
import 'package:petnote/state/app_settings_controller.dart';
import 'package:petnote/state/petnote_store.dart';

class DataStorageCoordinator extends ChangeNotifier {
  DataStorageCoordinator({
    required this.store,
    required this.settingsController,
    this.appLogController,
  });

  final PetNoteStore store;
  final AppSettingsController settingsController;
  final AppLogController? appLogController;

  PetNoteDataPackage? _latestSnapshotPackage;
  DataOperationResult? _latestOperationResult;

  DataOperationResult? get latestOperationResult => _latestOperationResult;

  String get dataSummary {
    return '宠物 ${store.pets.length} 只 · 待办 ${store.todos.length} 条 · '
        '提醒 ${store.reminders.length} 条 · 记录 ${store.records.length} 条';
  }

  Future<PetNoteDataPackage> createBackupPackage({
    required String packageName,
    required String description,
  }) async {
    final package = PetNoteDataPackage(
      schemaVersion: PetNoteDataPackage.currentSchemaVersion,
      packageType: PetNoteDataPackageType.backup,
      packageName: packageName,
      description: description,
      createdAt: DateTime.now(),
      appVersion: '1.0.0-beta.2+3',
      data: store.exportDataState(),
      settings: settingsController.exportNonSensitiveSettings(),
      meta: const <String, Object?>{'source': 'manual_export'},
    );
    _latestOperationResult = _resultForPackage(
      kind: DataOperationKind.backupExported,
      package: package,
      message: '完整备份已生成。',
      snapshotCreated: false,
      restoredSettings: false,
      isSuccess: true,
    );
    appLogController?.info(
      category: AppLogCategory.dataStorage,
      title: '生成完整备份',
      message: '完整备份包已生成。',
      details:
          'pets=${package.data.pets.length}, todos=${package.data.todos.length}, reminders=${package.data.reminders.length}, records=${package.data.records.length}',
    );
    notifyListeners();
    return package;
  }

  Future<DataOperationResult> importPackage({
    required PetNoteDataPackage package,
    DataImportOptions options = const DataImportOptions(),
  }) async {
    final validationError = validatePackage(package);
    if (validationError != null) {
      appLogController?.warning(
        category: AppLogCategory.dataStorage,
        title: '数据包校验失败',
        message: validationError,
        details: 'package=${package.packageName}',
      );
      return _setOperation(
        DataOperationResult(
          kind: DataOperationKind.validationFailed,
          isSuccess: false,
          message: validationError,
          snapshotCreated: false,
          restoredSettings: false,
          packageType: package.packageType,
          petsCount: package.data.pets.length,
          todosCount: package.data.todos.length,
          remindersCount: package.data.reminders.length,
          recordsCount: package.data.records.length,
        ),
      );
    }

    try {
      final snapshot = await _captureSnapshot();
      await store.replaceAllData(package.data);
      final restoredSettings =
          options.restoreSettings && package.settings != null;
      if (restoredSettings) {
        await settingsController.restoreNonSensitiveSettings(package.settings!);
      }
      appLogController?.info(
        category: AppLogCategory.dataStorage,
        title: '备份恢复完成',
        message: restoredSettings ? '备份数据和普通设置已恢复。' : '备份数据已恢复，当前设置保持不变。',
        details:
            'package=${package.packageName}\nrestoreSettings=$restoredSettings',
      );
      return _setOperation(
        _resultForPackage(
          kind: DataOperationKind.importedReplace,
          package: package,
          message: restoredSettings ? '备份数据和普通设置已恢复。' : '备份数据已恢复，当前设置保持不变。',
          snapshotCreated: snapshot != null,
          restoredSettings: restoredSettings,
          isSuccess: true,
        ),
      );
    } on StateError catch (error) {
      appLogController?.error(
        category: AppLogCategory.dataStorage,
        title: '导入失败',
        message: error.message,
        details: 'package=${package.packageName}',
      );
      return _setOperation(
        _resultForPackage(
          kind: DataOperationKind.validationFailed,
          package: package,
          message: error.message,
          snapshotCreated: false,
          restoredSettings: false,
          isSuccess: false,
        ),
      );
    }
  }

  Future<DataOperationResult> clearAllData() async {
    final snapshot = await _captureSnapshot();
    await store.clearAllData();
    await settingsController.resetNonSensitiveSettings();
    appLogController?.warning(
      category: AppLogCategory.dataStorage,
      title: '清空本地数据',
      message: '本地业务数据和普通设置已清空。',
      details: snapshot == null ? '未执行内部保护' : '已执行内部保护',
    );
    return _setOperation(
      DataOperationResult(
        kind: DataOperationKind.cleared,
        isSuccess: true,
        message: '本地业务数据和普通设置已清空。',
        snapshotCreated: snapshot != null,
        restoredSettings: false,
        packageType: null,
        petsCount: 0,
        todosCount: 0,
        remindersCount: 0,
        recordsCount: 0,
      ),
    );
  }

  PetNoteDataPackage parsePackageJson(String rawValue) {
    final decoded = jsonDecode(rawValue);
    if (decoded is! Map<String, dynamic>) {
      appLogController?.warning(
        category: AppLogCategory.dataStorage,
        title: '解析数据包失败',
        message: 'JSON 顶层结构不是对象。',
      );
      throw const FormatException('JSON 顶层结构必须是对象。');
    }
    final rawPackageType = decoded['packageType'] as String?;
    if (rawPackageType != null && rawPackageType != 'backup') {
      appLogController?.warning(
        category: AppLogCategory.dataStorage,
        title: '解析数据包失败',
        message: '当前仅支持完整备份文件。',
        details: 'packageType=$rawPackageType',
      );
      throw const FormatException('当前仅支持完整备份文件。');
    }
    appLogController?.info(
      category: AppLogCategory.dataStorage,
      title: '解析数据包成功',
      message: '文件内容已解析为数据包对象。',
    );
    return PetNoteDataPackage.fromJson(decoded);
  }

  String? validatePackage(PetNoteDataPackage package) {
    if (package.schemaVersion != PetNoteDataPackage.currentSchemaVersion) {
      return '数据包版本暂不支持。';
    }
    if (package.packageName.trim().isEmpty) {
      return '数据包缺少名称。';
    }
    if (package.data.pets.isEmpty &&
        package.data.todos.isEmpty &&
        package.data.reminders.isEmpty &&
        package.data.records.isEmpty) {
      return '数据包没有任何业务数据。';
    }
    try {
      store.exportDataState();
      store.exportDataState();
    } catch (_) {
      return '当前数据状态异常，暂时无法导入。';
    }
    return null;
  }

  Future<PetNoteDataPackage?> _captureSnapshot() async {
    final currentData = store.exportDataState();
    if (currentData.totalCount == 0 &&
        settingsController.aiProviderConfigs.isEmpty &&
        settingsController.themePreference == AppThemePreference.system) {
      _latestSnapshotPackage = null;
      return null;
    }
    _latestSnapshotPackage = PetNoteDataPackage(
      schemaVersion: PetNoteDataPackage.currentSchemaVersion,
      packageType: PetNoteDataPackageType.backup,
      packageName: '内部保护数据',
      description: '危险操作前自动生成，仅用于内部保护',
      createdAt: DateTime.now(),
      appVersion: '1.0.0-beta.2+3',
      data: currentData,
      settings: settingsController.exportNonSensitiveSettings(),
      meta: const <String, Object?>{'source': 'internal_protection'},
    );
    return _latestSnapshotPackage;
  }

  DataOperationResult _resultForPackage({
    required DataOperationKind kind,
    required PetNoteDataPackage package,
    required String message,
    required bool snapshotCreated,
    required bool restoredSettings,
    required bool isSuccess,
  }) {
    return DataOperationResult(
      kind: kind,
      isSuccess: isSuccess,
      message: message,
      snapshotCreated: snapshotCreated,
      restoredSettings: restoredSettings,
      packageType: package.packageType,
      petsCount: package.data.pets.length,
      todosCount: package.data.todos.length,
      remindersCount: package.data.reminders.length,
      recordsCount: package.data.records.length,
    );
  }

  DataOperationResult _setOperation(DataOperationResult result) {
    _latestOperationResult = result;
    notifyListeners();
    return result;
  }
}
