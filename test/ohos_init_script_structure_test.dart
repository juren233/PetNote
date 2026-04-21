import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OHOS init script resolves DevEco tools from configurable locations', () {
    final script = File('scripts/flutter-ohos.ps1').readAsStringSync();

    expect(script.contains(r'$env:DEVECO_HOME'), isTrue);
    expect(script.contains(r'$env:HARMONY_TOOLCHAIN_HOME'), isTrue);
    expect(
      script.contains("Get-OptionalCommandDirectory -Candidates @('ohpm.cmd', 'ohpm')"),
      isTrue,
    );
    expect(
      script.contains(
        "Get-OptionalCommandDirectory -Candidates @('hvigorw.bat', 'hvigorw')",
      ),
      isTrue,
    );
    expect(
      script.contains(r"'E:\Huawei\DevEco Studio\tools\ohpm\bin'"),
      isFalse,
    );
    expect(
      script.contains(r"'E:\Huawei\DevEco Studio\tools\hvigor\bin'"),
      isFalse,
    );
    expect(
      script.contains(r"'E:\Huawei\DevEco Studio\tools\node'"),
      isFalse,
    );
  });

  test('OHOS init script syncs version metadata from root pubspec.yaml', () {
    final script = File('scripts/flutter-ohos.ps1').readAsStringSync();

    expect(script.contains('function Get-PubspecVersionInfo {'), isTrue);
    expect(script.contains(r"Join-Path $RepoRoot 'pubspec.yaml'"), isTrue);
    expect(script.contains(r"if ($trimmedLine.StartsWith('version:'))"), isTrue);
    expect(script.contains(r'$pubspecVersionInfo.VersionName'), isTrue);
    expect(script.contains(r'$pubspecVersionInfo.VersionCode'), isTrue);
    expect(script.contains(r'"flutter.versionName=$versionName"'), isTrue);
    expect(script.contains(r'"flutter.versionCode=$versionCode"'), isTrue);
    expect(script.contains(r'[long]::TryParse($versionCode, [ref]$parsedVersionCode)'), isTrue);
    expect(script.contains(r"[string]$VersionName"), isTrue);
    expect(script.contains(r"[string]$VersionCode"), isTrue);
    expect(script.contains(r"$template.'version-name' = $VersionName"), isTrue);
    expect(script.contains(r"$template.'version-code' = [int64]$VersionCode"), isTrue);
  });
}
