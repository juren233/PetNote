# App 更新提醒 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Android 和 iOS 在检测到 GitHub Release 有新版时发送可点击的更新提醒通知，并在通知设置页提供默认开启的“更新提醒”开关；Harmony 不显示、不触发。

**Architecture:** 复用现有 `GitHubAppUpdateChecker` 作为唯一更新检测来源，新增独立的更新提醒通知发布通道，不复用待办/提醒 payload。设置状态落在 `AppSettingsController`，Root 启动阶段在平台、权限和开关满足时触发更新提醒；Android/iOS 原生通知点击直接打开 release URL。

**Tech Stack:** Flutter/Dart、SharedPreferences、MethodChannel、Android Kotlin NotificationCompat、iOS Swift UNUserNotificationCenter、Flutter widget/unit tests。

---

### Task 1: 设置状态持久化

**Files:**
- Modify: `lib/state/app_settings_controller.dart`
- Test: `test/app_settings_controller_test.dart`

**Step 1: Write failing tests**

Add tests that verify:

- `updateReminderEnabled` defaults to `true`.
- `setUpdateReminderEnabled(false)` persists and reloads as `false`.
- `resetNonSensitiveSettings()` resets it to `true`.

**Step 2: Run red test**

Run:

```bash
cmd.exe /C "E:\flutter\bin\flutter.bat test test\app_settings_controller_test.dart"
```

Expected: fails because `updateReminderEnabled` does not exist.

**Step 3: Implement minimal state**

Add:

- `static const String updateReminderEnabledStorageKey = 'update_reminder_enabled_v1';`
- private `_updateReminderEnabled = true`
- getter `updateReminderEnabled`
- method `setUpdateReminderEnabled(bool value)`
- load, restore, reset persistence handling

**Step 4: Run green test**

Run the same test command. Expected: pass.

---

### Task 2: 通知设置页开关

**Files:**
- Modify: `lib/app/me_page.dart`
- Test: `test/me_page_redesign_test.dart` or `test/ai_settings_widget_test.dart`

**Step 1: Write failing widget tests**

Cover:

- Android/iOS platform shows `ValueKey('notification_update_reminder_toggle')`.
- Harmony platform does not show the setting.
- Tapping the switch calls `setUpdateReminderEnabled`.

**Step 2: Run red test**

Run the focused widget test. Expected: fails because the setting does not exist.

**Step 3: Implement minimal UI**

Pass `settingsController` into `_NotificationSettingsPage`.

Render the top setting only when platform is Android or iOS:

- title: `更新提醒`
- subtitle: `检测到新版时，启动 App 会发送更新通知提醒。`
- iOS: use `CupertinoSwitch`
- Android: use a custom lightweight Liquid Glass styled switch using existing theme colors, rounded track, highlight, animated thumb; do not add new dependencies.

**Step 4: Run green test**

Run the focused widget test. Expected: pass.

---

### Task 3: 更新提醒通知发布接口

**Files:**
- Modify: `lib/notifications/notification_platform_adapter.dart`
- Modify: `lib/notifications/method_channel_notification_adapter.dart`
- Test: add or extend notification adapter test if present; otherwise cover through Root fake adapter.

**Step 1: Write failing test**

Add a fake adapter expectation that a method like `showUpdateNotification(AppUpdateInfo info)` can be called with title/body/release URL.

**Step 2: Run red test**

Expected: fails because adapter method does not exist.

**Step 3: Implement adapter method**

Add an abstract method:

```dart
Future<void> showUpdateNotification({
  required String versionLabel,
  required Uri releaseUrl,
});
```

MethodChannel implementation invokes `showUpdateNotification` with:

- `title`: `宠记App新版$versionLabel已发布`
- `body`: `点击查看更新内容`
- `releaseUrl`: `releaseUrl.toString()`

MissingPluginException should be a no-op.

**Step 4: Run green test**

Run focused tests. Expected: pass.

---

### Task 4: Root 启动检测与触发

**Files:**
- Modify: `lib/app/petnote_root.dart`
- Test: `test/notification_root_test.dart`

**Step 1: Write failing tests**

Cover:

- Given current build number 7 and latest update build number 9, Android/iOS platform + setting enabled + authorized permission triggers `showUpdateNotification`.
- Setting disabled does not trigger.
- Harmony platform does not trigger.
- Invalid current build number does not trigger.

**Step 2: Run red test**

Run:

```bash
cmd.exe /C "E:\flutter\bin\flutter.bat test test\notification_root_test.dart"
```

Expected: fails because Root does not check update notifications.

**Step 3: Implement minimal trigger**

Add optional `appUpdateChecker` injection to `PetNoteRoot` if needed for tests.

During startup after notification coordinator and settings are available:

- skip if `settingsController == null`
- skip if `!settingsController.updateReminderEnabled`
- skip if `defaultTargetPlatform == TargetPlatform.ohos`
- skip if permission is not authorized/provisional
- parse `widget.appVersionInfo.buildNumber`
- call `appUpdateChecker.fetchLatestUpdate`
- if result exists, call `coordinator.showUpdateNotification`

Do not block normal app startup if the request fails; log warning through `AppLogController`.

**Step 4: Run green test**

Run focused Root test. Expected: pass.

---

### Task 5: Android 原生通知直接打开 Release

**Files:**
- Modify: `android/app/src/main/kotlin/com/krustykrab/petnote/PetNoteNotificationBridge.kt`
- Modify if necessary: `android/app/src/main/AndroidManifest.xml`
- Test: add or extend Android structure test.

**Step 1: Write failing structure test**

Verify:

- `PetNoteNotificationBridge.kt` handles method `showUpdateNotification`.
- It reads `releaseUrl`.
- It builds an `Intent(Intent.ACTION_VIEW, Uri.parse(releaseUrl))`.
- The pending intent target is the browser/external URL, not the app launch intent payload.

**Step 2: Run red test**

Run focused structure test. Expected: fails.

**Step 3: Implement Android method**

In `PetNoteNotificationBridge.kt`:

- Add method branch `showUpdateNotification`.
- Check notification permission before posting.
- Build `NotificationCompat` with title/body and existing channel.
- Use a content `PendingIntent.getActivity` with `ACTION_VIEW` release URL intent.

**Step 4: Run green test**

Run focused structure test. Expected: pass.

---

### Task 6: iOS 原生通知直接打开 Release

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`
- Test: add or extend iOS structure test.

**Step 1: Write failing structure test**

Verify:

- `PetNoteNotificationPlugin` handles `showUpdateNotification`.
- It stores `releaseUrl` in notification `userInfo`.
- `userNotificationCenter(_:didReceive:)` detects update URL and calls `UIApplication.shared.open`.

**Step 2: Run red test**

Run focused structure test. Expected: fails.

**Step 3: Implement iOS method**

In `PetNoteNotificationPlugin`:

- Add `showUpdateNotification` method handling.
- Create `UNMutableNotificationContent` with title/body and `releaseUrl` userInfo.
- Schedule immediate `UNNotificationRequest`.
- In notification tap handler, if `releaseUrl` exists and is valid, open it directly and return without building Flutter launch intent.

**Step 4: Run green test**

Run focused structure test. Expected: pass.

---

### Task 7: Verification

Run focused tests:

```bash
cmd.exe /C "E:\flutter\bin\flutter.bat test test\app_settings_controller_test.dart test\notification_root_test.dart test\me_page_redesign_test.dart"
```

Run structure tests added/modified for Android and iOS.

After tests, check and clean `pubspec.lock` source noise:

```bash
git diff -- pubspec.lock
```

If dependency source changed from `https://pub.flutter-io.cn` to `https://pub.dev`, revert only that generated noise.
