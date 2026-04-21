import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PetNoteApp 优先使用启动前注入的应用版本信息并传给根页面', () {
    final source = File('lib/app/petnote_app.dart').readAsStringSync();

    expect(
        source.contains('this.appVersionInfo = AppVersionInfo.empty,'), isTrue);
    expect(source.contains('AppVersionInfo _appVersionInfo;'), isTrue);
    expect(source.contains('_appVersionInfo = widget.appVersionInfo;'), isTrue);
    expect(
        source.contains('if (_appVersionInfo == AppVersionInfo.empty) {'),
        isTrue);
    expect(source.contains('AppVersionInfo.load()'), isTrue);
    expect(source.contains('appVersionInfo: _appVersionInfo,'), isTrue);
  });
}
