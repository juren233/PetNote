import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:petnote/app/app_update_checker.dart';
import 'package:petnote/app/app_theme.dart';
import 'package:petnote/app/app_version_info.dart';
import 'package:petnote/app/me_page.dart';
import 'package:petnote/app/navigation_palette.dart';
import 'package:petnote/notifications/notification_models.dart';
import 'package:petnote/state/petnote_store.dart';
import 'package:petnote/state/app_settings_controller.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _ThrowingUrlLauncherPlatform extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    throw MissingPluginException();
  }
}

class _FakeAppUpdateChecker extends AppUpdateChecker {
  const _FakeAppUpdateChecker({this.result});

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

class _MePageTestHost extends StatefulWidget {
  const _MePageTestHost({
    required this.brightness,
    required this.appVersionInfo,
    required this.appUpdateChecker,
  });

  final Brightness brightness;
  final AppVersionInfo appVersionInfo;
  final AppUpdateChecker appUpdateChecker;

  @override
  State<_MePageTestHost> createState() => _MePageTestHostState();
}

class _MePageTestHostState extends State<_MePageTestHost> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildPetNoteTheme(widget.brightness),
      home: Scaffold(
        body: MePage(
          themePreference: AppThemePreference.system,
          onThemePreferenceChanged: (_) {},
          notificationPermissionState: NotificationPermissionState.unknown,
          notificationPushToken: null,
          onRequestNotificationPermission: null,
          onOpenNotificationSettings: null,
          onOpenExactAlarmSettings: null,
          settingsController: null,
          aiSettingsCoordinator: null,
          dataStorageCoordinator: null,
          appVersionInfo: widget.appVersionInfo,
          appUpdateChecker: widget.appUpdateChecker,
        ),
      ),
    );
  }
}

void main() {
  Future<void> pumpMePage(
    WidgetTester tester,
    Brightness brightness, {
    AppUpdateChecker appUpdateChecker = const _FakeAppUpdateChecker(),
    AppVersionInfo appVersionInfo = const AppVersionInfo(
      version: '1.2.3',
      buildNumber: '123',
    ),
  }) async {
    var selectedTheme = AppThemePreference.system;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPetNoteTheme(brightness),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: MePage(
                themePreference: selectedTheme,
                onThemePreferenceChanged: (value) {
                  setState(() => selectedTheme = value);
                },
                notificationPermissionState:
                    NotificationPermissionState.unknown,
                notificationPushToken: null,
                onRequestNotificationPermission: null,
                onOpenNotificationSettings: null,
                onOpenExactAlarmSettings: null,
                settingsController: null,
                aiSettingsCoordinator: null,
                dataStorageCoordinator: null,
                appVersionInfo: appVersionInfo,
                appUpdateChecker: appUpdateChecker,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('缺少平台插件时关于卡片仍可正常展示并给出失败提示', (tester) async {
    final originalUrlLauncherPlatform = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = _ThrowingUrlLauncherPlatform();

    addTearDown(() {
      UrlLauncherPlatform.instance = originalUrlLauncherPlatform;
    });

    await pumpMePage(
      tester,
      Brightness.light,
      appVersionInfo: const AppVersionInfo(
        version: '1.2.3',
        buildNumber: '123',
      ),
    );

    expect(find.text('Version 1.2.3'), findsOneWidget);

    final githubTitle = find.text('GitHub 仓库');
    await tester.ensureVisible(githubTitle);
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(of: githubTitle, matching: find.byType(InkWell)).first,
    );
    await tester.pump();

    expect(find.text('当前平台暂不支持打开外部链接'), findsOneWidget);
  });

  testWidgets('我的页重构为五个设置入口并移除旧列表堆叠', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'PetNote',
      packageName: 'com.juren233.petnote',
      version: '1.2.3',
      buildNumber: '123',
      buildSignature: 'test',
      installerStore: 'test-store',
    );
    await pumpMePage(tester, Brightness.light);

    expect(find.text('主题外观'), findsOneWidget);
    final themeTitleText = tester.widget<Text>(find.text('主题外观'));
    final themeTitleStyle = themeTitleText.style!;
    expect(themeTitleStyle.fontSize, greaterThan(15));
    expect(themeTitleStyle.fontWeight, FontWeight.w700);
    expect(find.text('AI配置'), findsOneWidget);
    expect(find.text('通知提醒'), findsOneWidget);
    expect(find.text('数据备份'), findsOneWidget);
    expect(find.text('宠记'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('me_theme_appearance_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_theme_slider')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_ai_config_entry')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_notification_entry')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_data_backup_entry')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_about_card')), findsOneWidget);
    expect(find.byKey(const ValueKey('me_about_logo_box')), findsOneWidget);
    expect(find.text('宠记'), findsOneWidget);
    expect(find.text('Version 1.2.3'), findsOneWidget);
    expect(find.text('宠物日常关怀记录App'), findsOneWidget);
    expect(find.text('GitHub 仓库'), findsOneWidget);
    expect(find.text('跳转查看更新'), findsOneWidget);
    expect(find.text('juren233'), findsOneWidget);
    expect(find.text('Developer'), findsNWidgets(2));
    expect(find.text('Ebato'), findsOneWidget);
    expect(find.text('Developer'), findsNWidgets(2));
    expect(find.text('AI 功能'), findsNothing);
    expect(find.text('隐私与关于'), findsNothing);

    expect(find.text('可手动指定主题，或继续跟随系统切换。'), findsNothing);
    expect(find.byKey(const ValueKey('theme_current_row')), findsNothing);
    expect(find.text('当前为跟随系统'), findsNothing);
    expect(find.byKey(const ValueKey('theme_slider_thumb_icon')), findsNothing);
    expect(find.text('设备'), findsOneWidget);
    expect(find.text('浅色'), findsOneWidget);
    expect(find.text('深色'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('theme_option_dark')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(find.text('当前为深色模式'), findsNothing);
    expect(find.byKey(const ValueKey('theme_slider_selected_dark')),
        findsOneWidget);
  });

  testWidgets('关于卡片首帧直接显示已预取的版本号', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildPetNoteTheme(Brightness.light),
        home: Scaffold(
          body: MePage(
            themePreference: AppThemePreference.system,
            onThemePreferenceChanged: (_) {},
            notificationPermissionState: NotificationPermissionState.unknown,
            notificationPushToken: null,
            onRequestNotificationPermission: null,
            onOpenNotificationSettings: null,
            onOpenExactAlarmSettings: null,
            settingsController: null,
            aiSettingsCoordinator: null,
            dataStorageCoordinator: null,
            appVersionInfo: const AppVersionInfo(
              version: '1.2.3',
              buildNumber: '123',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Version 1.2.3'), findsOneWidget);
    expect(find.text('Version --'), findsNothing);
  });

  testWidgets('关于卡片在父层回填版本信息后刷新本地版本并重跑更新检查',
      (tester) async {
    await tester.pumpWidget(
      const _MePageTestHost(
        brightness: Brightness.light,
        appVersionInfo: AppVersionInfo.empty,
        appUpdateChecker: _FakeAppUpdateChecker(),
      ),
    );

    expect(find.text('Version --'), findsOneWidget);
    expect(find.text('GitHub 仓库'), findsOneWidget);

    await tester.pumpWidget(
      _MePageTestHost(
        brightness: Brightness.light,
        appVersionInfo: const AppVersionInfo(
          version: '1.2.3',
          buildNumber: '7',
        ),
        appUpdateChecker: _FakeAppUpdateChecker(
          result: AppUpdateInfo(
            versionLabel: 'v1.0.3',
            buildNumber: 9,
            releaseUrl: Uri.parse(
              'https://github.com/juren233/PetNote/releases/tag/v1.0.3',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Version 1.2.3'), findsOneWidget);
    expect(find.text('Version --'), findsNothing);
    expect(find.text('🆕 当前App有新版 v1.0.3'), findsOneWidget);
    expect(find.text('🆕 当前App有新版 9'), findsNothing);
    expect(find.text('点击查看 v1.0.3 发布说明'), findsOneWidget);
  });

  testWidgets('关于卡片在深浅色模式下切换图标与版本胶囊样式', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'PetNote',
      packageName: 'com.juren233.petnote',
      version: '1.2.3',
      buildNumber: '123',
      buildSignature: 'test',
      installerStore: 'test-store',
    );

    await pumpMePage(tester, Brightness.light);

    final lightLogoBox = tester.widget<Container>(
      find.byKey(const ValueKey('me_about_logo_box')),
    );
    final lightLogoDecoration = lightLogoBox.decoration! as BoxDecoration;
    expect(lightLogoDecoration.color, Colors.white);
    expect(lightLogoDecoration.border!.top.color, const Color(0xFFEAE6E0));

    final lightVersionBadge = tester.widget<Container>(
      find.byKey(const ValueKey('me_about_version_badge')),
    );
    final lightVersionDecoration =
        lightVersionBadge.decoration! as BoxDecoration;
    expect(lightVersionDecoration.color, const Color(0xFFF6F1E9));
    expect(
      lightVersionDecoration.border!.top.color,
      const Color(0xFFE6DDD1),
    );

    final lightSvg = tester.widget<SvgPicture>(find.byType(SvgPicture).first);
    expect(lightSvg.colorFilter, isNull);

    await pumpMePage(tester, Brightness.dark);

    final darkLogoBox = tester.widget<Container>(
      find.byKey(const ValueKey('me_about_logo_box')),
    );
    final darkLogoDecoration = darkLogoBox.decoration! as BoxDecoration;
    expect(darkLogoDecoration.color, const Color(0xFF111111));
    expect(
      darkLogoDecoration.border!.top.color,
      Colors.white.withValues(alpha: 0.12),
    );

    final darkVersionBadge = tester.widget<Container>(
      find.byKey(const ValueKey('me_about_version_badge')),
    );
    final darkVersionDecoration = darkVersionBadge.decoration! as BoxDecoration;
    expect(
      darkVersionDecoration.color,
      Colors.white.withValues(alpha: 0.1),
    );
    expect(
      darkVersionDecoration.border!.top.color,
      Colors.white.withValues(alpha: 0.08),
    );

    final darkSvg = tester.widget<SvgPicture>(find.byType(SvgPicture).first);
    expect(
      darkSvg.colorFilter,
      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    );
  });

  testWidgets('检测到更高构建号时关于卡片展示新版提示', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'PetNote',
      packageName: 'com.juren233.petnote',
      version: '1.2.3',
      buildNumber: '7',
      buildSignature: 'test',
      installerStore: 'test-store',
    );

    await pumpMePage(
      tester,
      Brightness.light,
      appVersionInfo: const AppVersionInfo(
        version: '1.2.3',
        buildNumber: '7',
      ),
      appUpdateChecker: _FakeAppUpdateChecker(
        result: AppUpdateInfo(
          versionLabel: 'v1.0.3',
          buildNumber: 9,
          releaseUrl: Uri.parse(
            'https://github.com/juren233/PetNote/releases/tag/v1.0.3',
          ),
        ),
      ),
    );

    expect(find.text('Version 1.2.3'), findsOneWidget);
    expect(find.text('🆕 当前App有新版 v1.0.3'), findsOneWidget);
    expect(find.text('🆕 当前App有新版 9'), findsNothing);
    expect(find.text('点击查看 v1.0.3 发布说明'), findsOneWidget);
  });

  testWidgets('我的页功能型着色图标统一使用底栏我的激活色', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'PetNote',
      packageName: 'com.juren233.petnote',
      version: '1.2.3',
      buildNumber: '123',
      buildSignature: 'test',
      installerStore: 'test-store',
    );

    await pumpMePage(tester, Brightness.light);

    final context = tester.element(find.byType(MePage));
    final meAccentColor = tabAccentFor(context, AppTab.me).label;

    final tintedIcons = <IconData>[
      Icons.palette_rounded,
      Icons.auto_awesome_rounded,
      Icons.notifications_active_rounded,
      Icons.cloud_upload_rounded,
      Icons.code_rounded,
      Icons.person_outline_rounded,
    ];

    for (final iconData in tintedIcons) {
      final icons = tester.widgetList<Icon>(find.byIcon(iconData));
      expect(icons, isNotEmpty);
      for (final icon in icons) {
        expect(icon.color, meAccentColor);
      }
    }
  });
}
