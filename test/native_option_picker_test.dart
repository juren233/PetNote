import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petnote/app/native_option_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('petnote/native_option_picker');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('pickSingleOption decodes successful native response', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'pickSingleOption');
      return <String, Object?>{
        'status': 'success',
        'selectedValue': 'anthropic',
      };
    });

    final picker = MethodChannelNativeOptionPicker(channel: channel);
    final result = await picker.pickSingleOption(
      NativeOptionPickerRequest(
        title: '供应商类型',
        selectedValue: 'openai',
        options: const [
          NativeOptionItem(value: 'openai', label: 'OpenAI'),
          NativeOptionItem(value: 'anthropic', label: 'Anthropic'),
        ],
      ),
    );

    expect(result.status, NativeOptionPickerStatus.success);
    expect(result.selectedValue, 'anthropic');
  });

  test('pickSingleOption returns cancelled when user dismisses picker',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return <String, Object?>{
        'status': 'cancelled',
      };
    });

    final picker = MethodChannelNativeOptionPicker(channel: channel);
    final result = await picker.pickSingleOption(
      NativeOptionPickerRequest(
        title: '供应商类型',
        selectedValue: 'openai',
        options: const [
          NativeOptionItem(value: 'openai', label: 'OpenAI'),
        ],
      ),
    );

    expect(result.status, NativeOptionPickerStatus.cancelled);
    expect(result.selectedValue, isNull);
  });

  test('pickSingleOption maps malformed payload to invalid response',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => 'bad-payload');

    final picker = MethodChannelNativeOptionPicker(channel: channel);
    final result = await picker.pickSingleOption(
      NativeOptionPickerRequest(
        title: '供应商类型',
        selectedValue: 'openai',
        options: const [
          NativeOptionItem(value: 'openai', label: 'OpenAI'),
        ],
      ),
    );

    expect(result.status, NativeOptionPickerStatus.error);
    expect(result.errorCode, NativeOptionPickerErrorCode.invalidResponse);
  });

  test('pickSingleOption maps platform exception to unavailable', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'unavailable',
        message: 'picker unavailable',
      );
    });

    final picker = MethodChannelNativeOptionPicker(channel: channel);
    final result = await picker.pickSingleOption(
      NativeOptionPickerRequest(
        title: '供应商类型',
        selectedValue: 'openai',
        options: const [
          NativeOptionItem(value: 'openai', label: 'OpenAI'),
        ],
      ),
    );

    expect(result.status, NativeOptionPickerStatus.error);
    expect(result.errorCode, NativeOptionPickerErrorCode.unavailable);
    expect(result.errorMessage, contains('picker unavailable'));
  });
}
