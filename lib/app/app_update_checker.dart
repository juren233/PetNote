import 'dart:convert';
import 'dart:io';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.versionLabel,
    required this.buildNumber,
    required this.releaseUrl,
  });

  final String versionLabel;
  final int buildNumber;
  final Uri releaseUrl;
}

abstract class AppUpdateChecker {
  const AppUpdateChecker();

  Future<AppUpdateInfo?> fetchLatestUpdate({required int currentBuildNumber});
}

class GitHubAppUpdateChecker extends AppUpdateChecker {
  const GitHubAppUpdateChecker({
    this.latestReleaseApiUrl =
        'https://api.github.com/repos/juren233/PetNote/releases/latest',
    HttpClient Function()? httpClientFactory,
  }) : _httpClientFactory = httpClientFactory;

  final String latestReleaseApiUrl;
  final HttpClient Function()? _httpClientFactory;

  @override
  Future<AppUpdateInfo?> fetchLatestUpdate({
    required int currentBuildNumber,
  }) async {
    final release = await _fetchLatestRelease();
    if (release == null || release.buildNumber <= currentBuildNumber) {
      return null;
    }
    return release;
  }

  Future<AppUpdateInfo?> _fetchLatestRelease() async {
    final client = (_httpClientFactory ?? HttpClient.new)();
    try {
      final request = await client.getUrl(Uri.parse(latestReleaseApiUrl));
      request.headers
          .set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      request.headers.set(HttpHeaders.userAgentHeader, 'PetNote-App');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }
      final responseBody = await response.transform(utf8.decoder).join();
      final payload = jsonDecode(responseBody);
      if (payload is! Map<String, dynamic>) {
        return null;
      }
      return parseGitHubRelease(payload);
    } on FormatException {
      return null;
    } on HandshakeException {
      return null;
    } on HttpException {
      return null;
    } on SocketException {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static AppUpdateInfo? parseGitHubRelease(Map<String, dynamic> payload) {
    final buildNumber = _parseBuildNumber(payload['body']);
    final releaseUrl = _parseReleaseUrl(payload['html_url']);
    if (buildNumber == null || releaseUrl == null) {
      return null;
    }

    final versionLabel = _parseVersionLabel(
      tagName: payload['tag_name'],
      releaseName: payload['name'],
    );

    return AppUpdateInfo(
      versionLabel: versionLabel,
      buildNumber: buildNumber,
      releaseUrl: releaseUrl,
    );
  }

  static int? _parseBuildNumber(Object? body) {
    if (body is! String || body.isEmpty) {
      return null;
    }
    final hiddenMatch =
        RegExp(r'build-number:\s*(\d+)', caseSensitive: false).firstMatch(body);
    if (hiddenMatch != null) {
      return int.tryParse(hiddenMatch.group(1) ?? '');
    }
    final visibleMatch =
        RegExp(r'构建号[:：]\s*(\d+)', multiLine: true).firstMatch(body);
    return int.tryParse(visibleMatch?.group(1) ?? '');
  }

  static Uri? _parseReleaseUrl(Object? url) {
    if (url is! String || url.isEmpty) {
      return null;
    }
    return Uri.tryParse(url);
  }

  static String _parseVersionLabel({
    required Object? tagName,
    required Object? releaseName,
  }) {
    final candidates = [releaseName, tagName];
    for (final candidate in candidates) {
      if (candidate is! String || candidate.trim().isEmpty) {
        continue;
      }
      return candidate.trim();
    }
    return '未知版本';
  }
}
