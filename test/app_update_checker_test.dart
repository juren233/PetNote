import 'package:flutter_test/flutter_test.dart';
import 'package:petnote/app/app_update_checker.dart';

void main() {
  test('GitHub release 解析优先读取隐藏构建号元数据', () {
    final info = GitHubAppUpdateChecker.parseGitHubRelease({
      'tag_name': 'v1.0.2',
      'name': 'v1.0.2',
      'html_url': 'https://github.com/juren233/PetNote/releases/tag/v1.0.2',
      'body': '## 本次更新\n\n<!-- build-number: 7 -->',
    });

    expect(info, isNotNull);
    expect(info!.buildNumber, 7);
    expect(info.versionLabel, 'v1.0.2');
  });

  test('GitHub release 在缺少隐藏元数据时回退读取可见构建号', () {
    final info = GitHubAppUpdateChecker.parseGitHubRelease({
      'tag_name': 'v1.0.2',
      'name': 'v1.0.2',
      'html_url': 'https://github.com/juren233/PetNote/releases/tag/v1.0.2',
      'body': '## 版本元数据\n\n- 构建号：8',
    });

    expect(info, isNotNull);
    expect(info!.buildNumber, 8);
  });

  test('GitHub release 缺少构建号时不返回更新信息', () {
    final info = GitHubAppUpdateChecker.parseGitHubRelease({
      'tag_name': 'v1.0.2',
      'name': 'v1.0.2',
      'html_url': 'https://github.com/juren233/PetNote/releases/tag/v1.0.2',
      'body': '## 本次更新\n\n- 修复若干问题',
    });

    expect(info, isNull);
  });

  test('只有远端构建号更大时才视为有新版', () async {
    final checker = _FakeAppUpdateChecker(
      result: AppUpdateInfo(
        versionLabel: 'v1.0.3',
        buildNumber: 9,
        releaseUrl: Uri.parse(
          'https://github.com/juren233/PetNote/releases/tag/v1.0.3',
        ),
      ),
    );

    final newer = await checker.fetchLatestUpdate(currentBuildNumber: 7);
    final same = await checker.fetchLatestUpdate(currentBuildNumber: 9);

    expect(newer, isNotNull);
    expect(same, isNull);
  });
}

class _FakeAppUpdateChecker extends AppUpdateChecker {
  const _FakeAppUpdateChecker({required this.result});

  final AppUpdateInfo? result;

  @override
  Future<AppUpdateInfo?> fetchLatestUpdate(
      {required int currentBuildNumber}) async {
    if (result == null || result!.buildNumber <= currentBuildNumber) {
      return null;
    }
    return result;
  }
}
