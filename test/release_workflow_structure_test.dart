import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GitHub Release workflow 会把构建号写入发布说明元数据', () {
    final workflow = File('.github/workflows/release.yml').readAsStringSync();

    expect(
      workflow.contains(
        r'VERSION_BUILD: ${{ needs.resolve-release-plan.outputs.version_build }}',
      ),
      isTrue,
    );
    expect(workflow.contains('## 版本元数据'), isTrue);
    expect(
        workflow.contains("f\"- 构建号：{os.environ['VERSION_BUILD']}\""), isTrue);
    expect(workflow.contains('<!-- build-number: '), isTrue);
  });
}
