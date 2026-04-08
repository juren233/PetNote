import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OHOS build profile uses the current encrypted signing passwords',
      () async {
    final profile = File('ohos/build-profile.json5').readAsStringSync();

    expect(
      profile.contains(
        '000000166ace9124a329e5d8fc3a49c25ccec519fb953eb975064ea54568fbf0fc24f0a3f157',
      ),
      isTrue,
    );
    expect(
      profile.contains(
        '00000016762713284a02e305ac7c51dceaffb2c5ef66cb56b658857a077f6e6b3855d59d7260',
      ),
      isTrue,
    );
  });

  test('OHOS signing profile bundle-name matches app bundleName', () {
    final appJson = jsonDecode(
      File('ohos/AppScope/app.json5').readAsStringSync(),
    ) as Map<String, dynamic>;
    final profileJson = jsonDecode(
      File('ohos/sign/debug-profile.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final appBundleName = (appJson['app'] as Map<String, dynamic>)['bundleName'];
    final signingBundleName =
        (profileJson['bundle-info'] as Map<String, dynamic>)['bundle-name'];

    expect(signingBundleName, appBundleName);
  });
}
