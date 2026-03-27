# Pet Care Harmony

宠物照护管理应用，当前仓库同时维护三端：

- Android
- iOS
- HarmonyOS / OpenHarmony

这三个端共用同一套 Flutter 业务代码，但不共用同一套 Flutter SDK：

- Android + iOS 固定使用官方 Flutter
- HarmonyOS 固定使用项目内 OHOS Flutter

这份 README 重点说明“怎么开工程、怎么跑三端、哪些文件该提交、哪些不要提交”。

## 目录结构

- Flutter 共享层：
  - [pubspec.yaml](./pubspec.yaml)
  - [lib](./lib)
  - [test](./test)
- 官方 Flutter 平台层：
  - [android](./android)
  - [ios](./ios)
- Harmony 平台层：
  - [ohos](./ohos)
- 项目内 OHOS Flutter SDK 子模块：
  - [`.flutter_ohos_sdk_gitcode`](./.flutter_ohos_sdk_gitcode)
- 脚本入口：
  - [scripts/flutter-android.ps1](./scripts/flutter-android.ps1)
  - [scripts/flutter-ios.ps1](./scripts/flutter-ios.ps1)
  - [scripts/flutter-ohos.ps1](./scripts/flutter-ohos.ps1)
  - [scripts/flutter-state.ps1](./scripts/flutter-state.ps1)

## SDK 分流规则

- Android 默认读 [android/local.properties](./android/local.properties) 里的官方 Flutter 路径。
- iOS 默认复用 Android 同一套官方 Flutter。
- Harmony 默认读 [ohos/local.properties](./ohos/local.properties) 里的项目内 OHOS Flutter 路径。
- 根目录工作区默认以“官方 Flutter 状态”为准。
- Harmony 脚本运行前会临时切换到 OHOS Flutter 状态，结束后再恢复成官方 Flutter 状态。
- DevEco Studio 直接运行会使用仓库内自管的 OHOS hvigor 插件副本，并在构建前后自动切换 / 恢复根目录共享 Flutter 状态。

这意味着：

- 日常开发 Android / iOS 时，根目录应该保持官方 Flutter。
- 需要跑 Harmony 时，不要手动切 SDK，直接走 Harmony 脚本或 DevEco 的 Harmony 工程。

## 首次拉取

推荐直接递归拉取主仓库和子模块：

```bash
git clone --recursive <repo-url>
```

如果已经拉过主仓库，再执行一次：

```bash
git submodule update --init --recursive
```

说明：

- [`.flutter_ohos_sdk_gitcode`](./.flutter_ohos_sdk_gitcode) 是正式子模块，不是普通目录。
- 不要把 OHOS Flutter 整套源码直接复制进主仓库历史。
- Harmony 相关兼容修复通过仓库内自管插件副本、补丁文件和脚本自动应用，不依赖子模块里的本地脏改动。
- 对应补丁文件是 [tooling/ohos-flutter/flutter-hvigor-plugin.patch](./tooling/ohos-flutter/flutter-hvigor-plugin.patch)。
- 仓库内自管插件副本位于 [tooling/ohos-hvigor-plugin](./tooling/ohos-hvigor-plugin)。
- 当前受控入口是 [ohos/hvigorfile.ts](./ohos/hvigorfile.ts) 和 [ohos/hvigorconfig.ts](./ohos/hvigorconfig.ts) 的相对导入，不依赖 `ohos/package.json` 这种本地生成物长期保持某个值。

## IDE 使用方式

这是最容易混乱的地方，建议严格按下面用。

### Android / iOS

- 打开项目根目录 `.`
- 使用官方 Flutter
- 在 Android Studio / IntelliJ / VS Code 里调试 Android 和 iOS

你在根工程里通常会看到：

- Android 真机 / 模拟器
- iOS 设备 / 模拟器
- Windows / Web

你在根工程里通常**看不到**鸿蒙虚拟机，这是正常的。

### HarmonyOS

- 在 DevEco Studio 里打开 [ohos](./ohos)
- 使用 OHOS Flutter
- 在这个工程里调试鸿蒙真机 / 虚拟机
- 现在可以直接点 DevEco 的运行按钮，不需要再手动先跑一次 Harmony 脚本来切状态
- DevEco Studio 直接运行会使用仓库内自管的 OHOS hvigor 插件副本，而不是直接改动子模块里的 upstream 插件源码
- DevEco Studio 的一键编译 / 运行流程可用于 Windows，也可用于 macOS

你在 `ohos` 子工程里通常会看到：

- HarmonyOS 真机
- HarmonyOS 虚拟机

你在 `ohos` 子工程里不一定会像根工程那样完整显示 Flutter 设备列表，这是 DevEco 和普通 Flutter IDE 的识别方式差异，不是仓库坏了。

## 常用命令

以下命令默认都在项目根目录 `.` 执行。

### Android

```powershell
# 构建 Android release arm64 安装包
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-android.ps1 -Mode build -BuildMode release -TargetPlatform arm64

# 构建同时兼容 32 位和 64 位真机的 release 安装包
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-android.ps1 -Mode build -BuildMode release -TargetPlatform arm64+arm

# 调试 Android 真机
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-android.ps1 -Mode run -BuildMode debug -TargetPlatform arm64 -DeviceId <adb-device-id>

# 调试 Android 模拟器
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-android.ps1 -Mode run -BuildMode debug -TargetPlatform x64 -DeviceId <adb-device-id>

# 安装到指定 Android 设备
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-android.ps1 -Mode install -BuildMode release -TargetPlatform arm64 -DeviceId <adb-device-id>
```

如果 macOS 上没有安装 PowerShell 7，也可以直接走原生命令：

```bash
# 先同步官方 Flutter 依赖
flutter pub get

# 构建 Android release arm64 安装包
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons

# 构建同时兼容 32 位和 64 位真机的 release 安装包
flutter build apk --release --target-platform android-arm,android-arm64 --no-tree-shake-icons

# 调试 Android 真机 / 模拟器
flutter run --debug -d <adb-device-id>
```

说明：

- `arm64`：大多数 64 位 Android 真机
- `arm`：较老的 32 位 Android 真机
- `arm64+arm`：同时兼容 32 位和 64 位真机，适合本地手动发包
- `x64`：Android 模拟器
- 如果本机同时连了多台设备，建议显式传 `-DeviceId`
- release 构建会优先使用 [android/key.properties](./android/key.properties) 指向的正式签名；如果本地没有这份文件，则回退到 debug 签名
- 如果 macOS 上没有 `pwsh`，可以直接使用上面的 Android 原生命令
- 无 PowerShell 场景下，不会自动帮你切换 / 恢复共享 Flutter 状态；执行前请确认仓库根目录当前处于 `official` 状态

### iOS

Windows 上只做状态同步：

```powershell
# 仅同步官方 Flutter 依赖状态
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-ios.ps1 -Mode prepare
```

macOS 上请使用 `pwsh` 执行脚本：

```bash
# 安装 / 刷新 Pods
pwsh -File ./scripts/flutter-ios.ps1 -Mode pods

# 构建 iOS debug 包
pwsh -File ./scripts/flutter-ios.ps1 -Mode build -BuildMode debug

# 直接运行到指定 iPhone / 模拟器
pwsh -File ./scripts/flutter-ios.ps1 -Mode run -BuildMode debug -DeviceId <device-id>
```

如果 macOS 上没有安装 PowerShell 7，也可以直接走原生命令：

```bash
# 先同步官方 Flutter 依赖
flutter pub get

# 安装 / 刷新 Pods
cd ios && pod install && cd ..

# 构建 iOS debug 包（不签名）
flutter build ios --debug --no-codesign --no-tree-shake-icons

# 直接运行到指定 iPhone / 模拟器
flutter run --debug -d <device-id>
```

说明：

- Windows 上只能做 `prepare`
- 真正的 iOS 构建和运行必须在 macOS + Xcode + CocoaPods + PowerShell 7 (`pwsh`) 环境完成
- 如果 macOS 上没有 `pwsh`，可以直接使用上面的原生命令
- 无 PowerShell 场景下，不会自动帮你切换 / 恢复共享 Flutter 状态；执行前请确认仓库根目录当前处于 `official` 状态

### HarmonyOS

```powershell
# 跑测试
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-ohos.ps1 -Mode test

# 构建 x64 模拟器 HAP
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-ohos.ps1 -Mode build -TargetPlatform x64

# 构建 arm64 真机 HAP
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-ohos.ps1 -Mode build -TargetPlatform arm64

# 安装到 Harmony 虚拟机
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-ohos.ps1 -Mode install -TargetPlatform x64 -DeviceId 127.0.0.1:5555

# 构建、安装并启动 Harmony 虚拟机
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-ohos.ps1 -Mode run -TargetPlatform x64 -DeviceId 127.0.0.1:5555

# 构建、安装并启动 Harmony 真机
powershell -ExecutionPolicy Bypass -File .\scripts\flutter-ohos.ps1 -Mode run -TargetPlatform arm64 -DeviceId <hdc-device-id>
```

macOS 上如果不走 PowerShell 脚本，建议直接使用 DevEco Studio 一键编译 / 运行：

1. 安装 DevEco Studio for Mac，并在 SDK Manager 里装好 HarmonyOS / OpenHarmony SDK、toolchains、模拟器或真机调试组件
2. 用 DevEco Studio 打开 [ohos](./ohos)
3. 等待工程索引和依赖同步完成
4. 在运行配置里选择 `entry`
5. 连接 Harmony 真机或启动 Harmony 模拟器
6. 点击 DevEco 的运行按钮直接编译并运行

如果只想在 DevEco 里做一次纯构建，不直接启动设备，也可以：

1. 打开 [ohos](./ohos)
2. 选中 `entry`
3. 执行 DevEco 的 Build / Make Project
4. 让 IDE 直接产出对应 HAP

说明：

- 这套 macOS 场景指的是 DevEco Studio IDE 一键编译 / 运行
- 当前仓库没有提供经过验证的 macOS Harmony 命令行脚本
- 如果你要走命令行，请继续优先使用 Windows + [scripts/flutter-ohos.ps1](./scripts/flutter-ohos.ps1)

说明：

- Harmony 模拟器通常使用 `x64`
- Harmony 真机通常使用 `arm64`
- Harmony 命令行脚本当前按 Windows + DevEco Studio 工具链编写，建议只在 Windows 上执行
- macOS 可走 DevEco Studio 一键编译 / 运行，但不建议直接套用仓库里的 Harmony PowerShell 脚本
- 脚本会自动处理本地调试签名
- 脚本也会自动校验仓库内 hvigor 插件副本，避免 IDE / hvigor 误读根目录的官方 Flutter `package_config`
- DevEco 直跑链路也会做同样的状态隔离，不需要额外手动切 Flutter SDK

## 依赖状态管理

仓库里有两套本地状态快照：

- `official`：给 Android + iOS
- `ohos`：给 HarmonyOS

状态管理脚本是 [scripts/flutter-state.ps1](./scripts/flutter-state.ps1)，它会维护这些文件：

- [pubspec.lock](./pubspec.lock)
- `.flutter-plugins`
- `.flutter-plugins-dependencies`
- `.dart_tool/package_config.json`
- `.dart_tool/package_config_subset`
- `.dart_tool/package_graph.json`
- `.dart_tool/version`
- [android/local.properties](./android/local.properties)
- [ohos/local.properties](./ohos/local.properties)

结论很简单：

- 不要在三端之间手动来回执行裸 `flutter pub get`
- 需要哪一端，就走哪一端脚本
- Harmony 构建完后，根目录会恢复成官方 Flutter 状态，这是设计如此，不是状态错乱
- DevEco 直跑 Harmony 时，也会先备份根目录共享生成物，再切到 OHOS 状态，结束后恢复

## OHOS Hvigor 插件归属

- [`tooling/ohos-hvigor-plugin`](./tooling/ohos-hvigor-plugin) 是仓库内自管的 OHOS hvigor 插件副本。
- [ohos/hvigorfile.ts](./ohos/hvigorfile.ts) 和 [ohos/hvigorconfig.ts](./ohos/hvigorconfig.ts) 会直接相对导入这份仓库内副本。
- 不再直接修改 OHOS Flutter 子模块里的 hvigor 插件源码。
- [`.flutter_ohos_sdk_gitcode`](./.flutter_ohos_sdk_gitcode) 仍然只是 OHOS Flutter SDK 子模块，不承载项目本地业务定制。

这样做的原因很明确：

- upstream 子模块仓库不是我们的，不能依赖向上游提交本地定制。
- 如果把关键行为建立在子模块脏改动上，`git status` 会长期脏，而且新机器难以复现。
- 把 hvigor 插件副本收回主仓库后，DevEco 直跑能力才能随主仓库一起提交、评审和同步。
- upstream Flutter 工具偶尔会重写 `ohos/package.json` 和 `ohos/node_modules`，但那只是本地生成物；真正决定 DevEco 入口的是 [ohos/hvigorfile.ts](./ohos/hvigorfile.ts) 和 [ohos/hvigorconfig.ts](./ohos/hvigorconfig.ts)。

升级注意事项：

- 升级 [`.flutter_ohos_sdk_gitcode`](./.flutter_ohos_sdk_gitcode) 时，不要直接在子模块里手改 hvigor 插件源码。
- 应该对照 upstream 的 hvigor 插件变更，再同步更新 [tooling/ohos-hvigor-plugin](./tooling/ohos-hvigor-plugin)。
- 提交前确认 [`.flutter_ohos_sdk_gitcode`](./.flutter_ohos_sdk_gitcode) 没有本地脏改动。

## 提交规范

建议提交：

- 共享业务代码改动
- Android / iOS / Harmony 平台代码改动
- 脚本改动
- [`.gitmodules`](./.gitmodules)
- [README.md](./README.md)
- [tooling/ohos-hvigor-plugin](./tooling/ohos-hvigor-plugin)
- [tooling/ohos-flutter/flutter-hvigor-plugin.patch](./tooling/ohos-flutter/flutter-hvigor-plugin.patch)
- 子模块指针 [`.flutter_ohos_sdk_gitcode`](./.flutter_ohos_sdk_gitcode) 的版本更新

不要提交：

- `.tooling/flutter-state/`
- `.dart_tool/`
- `.flutter-plugins`
- `.flutter-plugins-dependencies`
- `ohos/node_modules/`
- `ohos/oh_modules/`
- 构建产物目录

特别注意：

- 如果 [`.flutter_ohos_sdk_gitcode`](./.flutter_ohos_sdk_gitcode) 在主仓库里显示为 `dirty`，先清掉子模块内部的本地改动再提主仓库。
- 根目录 [pubspec.lock](./pubspec.lock) 提交前应保持“官方 Flutter 默认状态”。
- 如果需要改 DevEco 直跑逻辑，请优先改 [tooling/ohos-hvigor-plugin](./tooling/ohos-hvigor-plugin)，不要去改子模块里的 upstream hvigor 插件源码。

## 团队协作建议

三个人协作时，推荐按“两条工具链 + 共享层”分工，而不是按三个平台硬切。

- 1 人主看共享业务层：
  - [lib](./lib)
  - [test](./test)
- 1 人主看官方 Flutter 平台层：
  - [android](./android)
  - [ios](./ios)
- 1 人主看 Harmony 平台层：
  - [ohos](./ohos)
  - [`.flutter_ohos_sdk_gitcode`](./.flutter_ohos_sdk_gitcode)

提交前最低验证建议：

- 共享层改动：至少验证 Android 和 Harmony
- Android 平台改动：跑一次 [scripts/flutter-android.ps1](./scripts/flutter-android.ps1)
- iOS 平台改动：在 macOS 上跑一次 [scripts/flutter-ios.ps1](./scripts/flutter-ios.ps1)
- Harmony 平台改动：跑一次 [scripts/flutter-ohos.ps1](./scripts/flutter-ohos.ps1)

## 常见误区

- “为什么根工程设备列表里没有鸿蒙虚拟机？”
  因为根工程走的是官方 Flutter，不会列出 OHOS 设备。

- “为什么跑完 Harmony 脚本后，根目录又变回官方 Flutter 了？”
  因为这正是分流设计，避免影响 Android / iOS。

- “为什么 DevEco 现在可以直接运行了？”
  因为 hvigor 插件会在构建前自动备份共享状态、切换到 OHOS Flutter、必要时刷新 `package_config`，构建后再恢复。

- “为什么 DevEco 运行前有时仍然建议先跑一次 Harmony 脚本？”
  因为脚本会顺手完成子模块初始化、签名修复和 hvigor 补丁兜底，适合首次拉仓库或本地环境刚变化之后使用。

- “为什么不要直接把 OHOS Flutter SDK 当普通目录提交？”
  因为体积太大，而且不利于升级和团队同步，子模块更可控。
