# App 更新提醒设计

> 目标：在沿用现有 GitHub Release 更新检测链路的前提下，为 Android 与 iOS 增加“检测到新版时发本地通知”的能力，并在通知设置页提供“更新提醒”开关；HarmonyOS 不提供该功能与设置入口。

## 背景

- 当前关于卡片会通过 `GitHubAppUpdateChecker` 检测 GitHub Release 是否存在更高构建号的新版本。
- 当前通知链路主要服务待办与提醒事项，本地通知点击后会回到 App 并按既有 payload 路由处理。
- 本次需求要求：
  - Android / iOS 在启动检测到新版时追加一条本地通知。
  - 通知标题固定为“宠记App新版[版本号]已发布”，正文固定为“点击查看更新内容”。
  - 点击通知后不回 App，直接打开对应 release 页面。
  - 在“通知提醒”设置页顶部新增“更新提醒”开关。
  - 开关默认开启，关闭后不再触发更新提醒通知。
  - iOS 开关使用原生风格；Android 使用现有 Liquid Glass 视觉语言；HarmonyOS 不显示该设置项，也不触发更新提醒。

## 边界约束

### 允许变化

- 新增或调整与“版本更新提醒”直接相关的 Dart 状态、设置持久化、Root 启动逻辑、通知设置页 UI、Android / iOS 原生通知跳转实现。
- 扩展现有版本检测结果在 Root 层的复用方式。

### 禁止变化

- 不改变关于卡片现有的展示口径与“有新版”文案。
- 不改变 GitHub Release 解析规则与现有构建号比较口径。
- 不把“更新提醒”塞进现有待办/提醒 payload 语义里。
- 不给 HarmonyOS 暴露无效的设置开关或伪实现。

## 方案选择

### 选定方案

采用“复用现有版本检测 + 追加独立更新通知 + 原生外链跳转”的方案：

1. 版本检测仍由现有 `GitHubAppUpdateChecker` 提供，不新增第二套远端接口。
2. Root 启动阶段复用同一检测链路拿到最新 release 信息。
3. 当检测到新版、当前平台为 Android / iOS、通知权限允许且“更新提醒”开关开启时，立即发送一条本地通知。
4. 该通知不复用待办/提醒 payload；改为在原生层直接携带 release URL，并在点击通知时直接打开浏览器。
5. 通知设置页顶部展示“更新提醒”开关：
   - iOS：使用 `CupertinoSwitch` 风格。
   - Android：使用项目现有 Liquid Glass 视觉语言做定制开关样式。
   - HarmonyOS：不渲染该设置项。

### 为什么不走“点击通知回 App 再跳转”

- 用户已经明确要求可以直接打开对应 release，无需回 App。
- 直接原生外链跳转能避免扩展 Flutter 通知启动意图模型，减少对现有待办/提醒通知语义的侵入。
- 对当前需求来说更简单、改动更小，也更符合“新版提示”这类一次性阅读场景。

## 设计细节

### 1. 设置持久化

在 `AppSettingsController` 中新增：

- 存储键：`update_reminder_enabled_v1`
- 运行时字段：`bool _updateReminderEnabled`
- 公开只读 getter：`bool get updateReminderEnabled`
- 更新方法：`Future<void> setUpdateReminderEnabled(bool value)`

默认值为 `true`。

该值仅控制“是否发更新提醒通知”，不影响：

- 关于卡片的版本检测与展示
- 版本号徽标展示
- GitHub 仓库入口与 release 链接跳转

### 2. Root 启动检测复用

在 `PetNoteRoot` 或其直接相关启动链路里补一段轻量更新检查：

- 条件：
  - `AppSettingsController` 已加载
  - 平台不是 HarmonyOS
  - 当前平台具备通知能力（至少不是 unsupported）
  - `updateReminderEnabled == true`
- 行为：
  - 复用 `GitHubAppUpdateChecker.fetchLatestUpdate(currentBuildNumber: ...)`
  - 检测到新版后，调用“更新提醒通知发布器”发本地通知

为了避免与关于卡片形成两份不一致逻辑，更新判断继续完全以 `AppUpdateInfo` 为准。

### 3. 更新提醒通知模型

不修改现有待办/提醒 `NotificationPayload` 的语义。

新增一条独立的“更新提醒通知”发布通道，最小必要字段：

- `notificationId/key`
- `title`
- `body`
- `releaseUrl`

这条通知不进入现有 `NotificationCoordinator.syncFromStore()` 的待办调度快照，也不参与待办/提醒的幂等同步规则。

原因：

- 它不是业务待办提醒。
- 你要求每次启动只要检测到新版就可以再次通知，不需要复用当前清单类通知的去重语义。

### 4. 原生点击行为

#### Android

- 在现有通知桥新增专用于“更新提醒通知”的调度方法。
- 原生通知点击后直接通过浏览器 Intent 打开 release URL。
- 不再回传 Flutter payload。

#### iOS

- 对应新增本地通知调度与点击打开 release URL 的原生实现。
- 点击通知直接打开外部浏览器访问 release 页面。

#### HarmonyOS

- 不新增实现。
- Root 层直接跳过更新提醒逻辑。

### 5. 通知设置页展示

在 `通知提醒` 页面顶部新增一个“更新提醒”设置块，位于权限说明与操作按钮之前。

文案：

- 标题：`更新提醒`
- 副标题：`检测到新版时，启动 App 会发送更新通知提醒。`

平台展示规则：

- iOS：显示，使用原生风格开关。
- Android：显示，使用 Liquid Glass 风格开关。
- HarmonyOS：隐藏整个设置项。

### 6. Android 样式策略

不额外引入新的 UI 依赖；优先复用仓库已存在的：

- `io.github.kyant0:backdrop`
- `io.github.kyant0:shapes`

以及现有底栏 Liquid Glass 视觉实现中的颜色、模糊、描边与高光语言，提炼一个足够轻量的 Android 开关样式，避免为了一个设置项复制一整套底栏复杂交互实现。

## 影响文件（预估）

### 必改

- `lib/state/app_settings_controller.dart`
- `lib/app/me_page.dart`
- `lib/app/petnote_root.dart`
- `lib/app/app_update_checker.dart`（如果需要抽取更好复用的检测入口）
- `lib/notifications/method_channel_notification_adapter.dart`

### Android 直接相关

- `android/app/src/main/kotlin/com/krustykrab/petnote/PetNoteNotificationBridge.kt`
- `android/app/src/main/kotlin/com/krustykrab/petnote/PetNoteNotificationReceiver.kt`

### iOS 直接相关

- 对应通知桥与点击跳转原生文件（待按仓库现状定位最小必要文件）

### 测试

- `test/app_settings_controller_test.dart`
- `test/me_page_redesign_test.dart` 或通知设置相关 widget test
- `test/notification_root_test.dart`
- 可能新增 Android / iOS 结构测试文件

## 验证计划

1. 控制器测试：确认“更新提醒”默认开启，修改后能持久化恢复。
2. Widget 测试：确认通知设置页顶部出现“更新提醒”开关；Harmony 不出现。
3. Root / 启动逻辑测试：
   - 检测到新版 + 开关开启 + Android/iOS → 触发更新通知
   - 开关关闭 → 不触发
   - Harmony → 不触发
4. Android / iOS 结构验证：确认原生通知点击目标是 release URL，而不是回 App payload。

## 风险与注意点

- 如果 iOS 当前通知原生桥接能力较弱，可能需要补最小必要的本地通知点击处理链路，这部分是本次最容易扩出范围的地方，需要坚持最小实现。
- 由于用户明确要求“每次启动都通知”，不做版本去重；这会增加提醒频率，但属于确认后的产品行为，不应在实现中偷偷收敛为“一次通知”。
- Android 样式实现要克制，不要为一个开关把底栏那套复杂平台视图完整搬过来。
