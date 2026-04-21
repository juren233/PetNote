import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android MainActivity 在原生层固定为竖屏', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(
      manifest.contains('android:screenOrientation="portrait"'),
      isTrue,
      reason: 'Android 原生入口必须显式锁定 portrait，避免旋转后重建界面。',
    );
  });

  test('Harmony Ability 在原生层固定为竖屏', () {
    final moduleJson =
        File('ohos/entry/src/main/module.json5').readAsStringSync();

    expect(
      moduleJson.contains('"orientation": "portrait"'),
      isTrue,
      reason: 'Harmony 原生 Ability 必须显式锁定 portrait，避免启动期通过 Flutter 平台通道切方向。',
    );
  });

  test('iOS 仅声明竖屏方向', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(
        infoPlist.contains('<string>UIInterfaceOrientationPortrait</string>'),
        isTrue);
    expect(infoPlist.contains('UIInterfaceOrientationLandscapeLeft'), isFalse);
    expect(infoPlist.contains('UIInterfaceOrientationLandscapeRight'), isFalse);
    expect(infoPlist.contains('UIInterfaceOrientationPortraitUpsideDown'),
        isFalse);
  });
}
