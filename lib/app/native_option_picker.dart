import 'package:flutter/services.dart';
import 'package:petnote/logging/app_log_controller.dart';

enum NativeOptionPickerStatus {
  success,
  cancelled,
  error,
}

enum NativeOptionPickerErrorCode {
  cancelled,
  unavailable,
  invalidResponse,
  platformError,
}

class NativeOptionItem {
  const NativeOptionItem({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'value': value,
      'label': label,
    };
  }
}

class NativeOptionPickerRequest {
  const NativeOptionPickerRequest({
    required this.title,
    required this.options,
    this.selectedValue,
  });

  final String title;
  final String? selectedValue;
  final List<NativeOptionItem> options;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'title': title,
      'selectedValue': selectedValue,
      'options': options.map((option) => option.toJson()).toList(),
    };
  }
}

class NativeOptionPickerResult {
  const NativeOptionPickerResult._({
    required this.status,
    this.selectedValue,
    this.errorCode,
    this.errorMessage,
  });

  const NativeOptionPickerResult.success({
    required String selectedValue,
  }) : this._(
          status: NativeOptionPickerStatus.success,
          selectedValue: selectedValue,
        );

  const NativeOptionPickerResult.cancelled()
      : this._(status: NativeOptionPickerStatus.cancelled);

  const NativeOptionPickerResult.error({
    required NativeOptionPickerErrorCode errorCode,
    required String errorMessage,
  }) : this._(
          status: NativeOptionPickerStatus.error,
          errorCode: errorCode,
          errorMessage: errorMessage,
        );

  final NativeOptionPickerStatus status;
  final String? selectedValue;
  final NativeOptionPickerErrorCode? errorCode;
  final String? errorMessage;

  bool get isSuccess => status == NativeOptionPickerStatus.success;
  bool get isCancelled => status == NativeOptionPickerStatus.cancelled;
}

abstract class NativeOptionPicker {
  Future<NativeOptionPickerResult> pickSingleOption(
    NativeOptionPickerRequest request,
  );
}

class MethodChannelNativeOptionPicker implements NativeOptionPicker {
  MethodChannelNativeOptionPicker({
    MethodChannel? channel,
    this.appLogController,
  }) : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'petnote/native_option_picker';

  final MethodChannel _channel;
  final AppLogController? appLogController;

  @override
  Future<NativeOptionPickerResult> pickSingleOption(
    NativeOptionPickerRequest request,
  ) async {
    try {
      appLogController?.info(
        category: AppLogCategory.nativeBridge,
        title: '调用原生选项选择器',
        message: '开始打开原生单选面板：${request.title}',
      );
      final rawResponse = await _channel.invokeMethod<Object?>(
        'pickSingleOption',
        request.toJson(),
      );
      if (rawResponse is! Map<Object?, Object?>) {
        return const NativeOptionPickerResult.error(
          errorCode: NativeOptionPickerErrorCode.invalidResponse,
          errorMessage: '原生选项选择器返回了无效数据。',
        );
      }
      final status = rawResponse['status'] as String?;
      switch (status) {
        case 'success':
          final selectedValue = rawResponse['selectedValue'];
          if (selectedValue is! String || selectedValue.isEmpty) {
            return const NativeOptionPickerResult.error(
              errorCode: NativeOptionPickerErrorCode.invalidResponse,
              errorMessage: '原生选项选择器没有返回有效的选项值。',
            );
          }
          appLogController?.info(
            category: AppLogCategory.nativeBridge,
            title: '原生选项选择成功',
            message: '已选择：$selectedValue',
          );
          return NativeOptionPickerResult.success(
            selectedValue: selectedValue,
          );
        case 'cancelled':
          appLogController?.warning(
            category: AppLogCategory.nativeBridge,
            title: '原生选项选择取消',
            message: '用户取消了原生单选面板：${request.title}',
          );
          return const NativeOptionPickerResult.cancelled();
        case 'error':
          final errorCode = _parseErrorCode(rawResponse['errorCode'] as String?);
          final errorMessage =
              rawResponse['errorMessage'] as String? ?? '原生选项选择器当前不可用。';
          appLogController?.error(
            category: AppLogCategory.nativeBridge,
            title: '原生选项选择失败',
            message: errorMessage,
            details: 'code: ${rawResponse['errorCode'] ?? ''}',
          );
          return NativeOptionPickerResult.error(
            errorCode: errorCode,
            errorMessage: errorMessage,
          );
        default:
          return const NativeOptionPickerResult.error(
            errorCode: NativeOptionPickerErrorCode.invalidResponse,
            errorMessage: '原生选项选择器返回了未知状态。',
          );
      }
    } on MissingPluginException {
      return const NativeOptionPickerResult.error(
        errorCode: NativeOptionPickerErrorCode.unavailable,
        errorMessage: '当前平台暂未接入原生选项选择器。',
      );
    } on PlatformException catch (error) {
      return NativeOptionPickerResult.error(
        errorCode: NativeOptionPickerErrorCode.unavailable,
        errorMessage: error.message ?? '当前平台暂未接入原生选项选择器。',
      );
    }
  }

  static NativeOptionPickerErrorCode _parseErrorCode(String? value) {
    return switch (value) {
      'cancelled' => NativeOptionPickerErrorCode.cancelled,
      'invalidResponse' => NativeOptionPickerErrorCode.invalidResponse,
      'platformError' => NativeOptionPickerErrorCode.platformError,
      _ => NativeOptionPickerErrorCode.unavailable,
    };
  }
}
