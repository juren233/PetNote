import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petnote/app/system_ui_policy.dart';

void main() {
  test(
      'OHOS startup policy avoids edge-to-edge until flutter_ohos window handling is stable',
      () {
    expect(ohosStartupSystemUiPolicy.mode, isNull);
    expect(
      ohosStartupSystemUiPolicy.overlayStyle.statusBarColor,
      const Color(0x00000000),
    );
  });

  test('启动竖屏策略只允许 portraitUp', () {
    expect(appPortraitOrientations, [DeviceOrientation.portraitUp]);
  });

  test('OHOS 竖屏不走 Flutter 平台通道', () async {
    await lockAppToPortrait(platformName: 'ohos');
  });
}
