import 'package:flutter_test/flutter_test.dart';
import 'package:petnote/logging/app_log_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists and restores local log entries', () async {
    final controller = await AppLogController.load();

    controller.info(
      category: AppLogCategory.ai,
      title: '测试标题',
      message: '测试消息',
      details: 'detail',
    );

    final reloaded = await AppLogController.load();

    expect(reloaded.entries, hasLength(1));
    expect(reloaded.entries.single.title, '测试标题');
    expect(reloaded.entries.single.message, '测试消息');
    expect(reloaded.entries.single.details, 'detail');
  });

  test('keeps only the newest bounded number of entries', () async {
    final controller = await AppLogController.load();

    for (var index = 0; index < AppLogController.maxEntries + 20; index += 1) {
      controller.info(
        category: AppLogCategory.notifications,
        title: '标题$index',
        message: '消息$index',
      );
    }

    expect(controller.entries, hasLength(AppLogController.maxEntries));
    expect(controller.entries.first.title,
        '标题${AppLogController.maxEntries + 19}');
    expect(controller.entries.last.title, '标题20');
  });

  test('persists and restores crash diagnostics entries', () async {
    final controller = await AppLogController.load();

    controller.captureUnhandledDartError(
      StateError('zone boom'),
      StackTrace.current,
      source: 'zone',
    );

    final reloaded = await AppLogController.load();

    expect(reloaded.crashDiagnosticEntries, hasLength(1));
    expect(
      reloaded.crashDiagnosticEntries.single.title,
      '捕获未处理 Dart 异常',
    );
    expect(
      reloaded.crashDiagnosticEntries.single.message,
      contains('zone boom'),
    );
  });

  test('records suspected abnormal exit when previous session stayed active',
      () async {
    final controller = await AppLogController.load();

    controller.beginCrashMonitoringSession();

    final reloaded = await AppLogController.load();

    expect(
      reloaded.crashDiagnosticEntries.map((entry) => entry.title),
      contains('检测到上次疑似异常退出'),
    );
    expect(reloaded.crashDiagnosticsStatus.hasSuspectedAbnormalExit, isTrue);
  });

  test('does not report abnormal exit after a normal session end', () async {
    final controller = await AppLogController.load();

    controller.beginCrashMonitoringSession();
    controller.endCrashMonitoringSession(reason: 'dispose');

    final reloaded = await AppLogController.load();

    expect(
      reloaded.crashDiagnosticEntries.map((entry) => entry.title),
      isNot(contains('检测到上次疑似异常退出')),
    );
    expect(reloaded.crashDiagnosticsStatus.hasSuspectedAbnormalExit, isFalse);
  });
}
