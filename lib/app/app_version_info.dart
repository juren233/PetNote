import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  const AppVersionInfo({
    required this.version,
    required this.buildNumber,
  });

  final String version;
  final String buildNumber;

  static const AppVersionInfo empty = AppVersionInfo(
    version: '',
    buildNumber: '',
  );

  static Future<AppVersionInfo> load() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return AppVersionInfo(
        version: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
      );
    } on PlatformException {
      return empty;
    } on MissingPluginException {
      return empty;
    }
  }
}
