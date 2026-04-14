import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OHOS 应用名资源根据语言环境提供正确文案', () {
    final appJson5 = File('ohos/AppScope/app.json5').readAsStringSync();
    final moduleJson5 = File('ohos/entry/src/main/module.json5').readAsStringSync();

    expect(
      appJson5.contains('"label": "\$string:app_name"'),
      isTrue,
      reason: 'OHOS app label 必须继续引用 app_name 资源',
    );
    expect(
      moduleJson5.contains('"label": "\$string:EntryAbility_label"'),
      isTrue,
      reason: 'OHOS EntryAbility label 必须继续引用 EntryAbility_label 资源',
    );
    expect(
      _readStringValue('ohos/AppScope/resources/base/element/string.json', 'app_name'),
      '宠记',
      reason: 'OHOS 默认应用名必须是宠记',
    );
    expect(
      _readStringValue('ohos/AppScope/resources/en_US/element/string.json', 'app_name'),
      'PetNote',
      reason: 'OHOS 英文应用名必须是 PetNote',
    );
    expect(
      _readStringValue('ohos/entry/src/main/resources/base/element/string.json', 'EntryAbility_label'),
      '宠记',
      reason: 'OHOS 默认入口能力名称必须是宠记',
    );
    expect(
      _readStringValue('ohos/entry/src/main/resources/zh_CN/element/string.json', 'EntryAbility_label'),
      '宠记',
      reason: 'OHOS 中文入口能力名称必须是宠记',
    );
    expect(
      _readStringValue('ohos/entry/src/main/resources/en_US/element/string.json', 'EntryAbility_label'),
      'PetNote',
      reason: 'OHOS 英文入口能力名称必须是 PetNote',
    );
  });
}

String _readStringValue(String path, String name) {
  final jsonText = File(path).readAsStringSync();
  final data = jsonDecode(jsonText) as Map<String, dynamic>;
  final strings = (data['string'] as List).cast<Map<String, dynamic>>();
  final entry = strings.singleWhere((item) => item['name'] == name);
  return entry['value'] as String;
}
