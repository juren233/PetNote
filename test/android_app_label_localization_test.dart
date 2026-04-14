import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android 应用名资源根据语言环境提供正确文案', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final baseStrings = File('android/app/src/main/res/values/strings.xml').readAsStringSync();
    final englishStrings =
        File('android/app/src/main/res/values-en/strings.xml').readAsStringSync();

    expect(
      manifest.contains('android:label="@string/app_name"'),
      isTrue,
      reason: 'application 标签必须改为资源引用，不能写死中文',
    );
    expect(
      RegExp(
        r'<activity[^>]*android:name="\.MainActivity"[\s\S]*?android:label="@string/app_name"',
      ).hasMatch(manifest),
      isTrue,
      reason: 'MainActivity 必须显式引用应用名资源，确保后台卡片跟随本地化',
    );
    expect(
      baseStrings.contains('<string name="app_name">宠记</string>'),
      isTrue,
      reason: '默认 Android 应用名必须是宠记',
    );
    expect(
      englishStrings.contains('<string name="app_name">PetNote</string>'),
      isTrue,
      reason: '英文 Android 应用名必须是 PetNote',
    );
  });
}
