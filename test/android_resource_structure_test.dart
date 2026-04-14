import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android launcher background color is defined exactly once', () {
    final valuesDir = Directory('android/app/src/main/res/values');
    final definitionCount = valuesDir
        .listSync()
        .whereType<File>()
        .map((file) => file.readAsStringSync())
        .map(
          (source) =>
              RegExp(r'<color name="ic_launcher_background">').allMatches(source).length,
        )
        .fold<int>(0, (sum, count) => sum + count);

    expect(definitionCount, 1);
  });
}
