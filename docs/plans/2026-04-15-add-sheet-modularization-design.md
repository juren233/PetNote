# Add Sheet 模块化设计

**日期：** 2026-04-15

**目标：** 在不改变现有业务行为、动画表现、`ValueKey` 字面值和提交流程的前提下，对 [`lib/app/add_sheet.dart`](/F:/HarmonyProject/Pet/lib/app/add_sheet.dart) 做职责拆分，降低单文件复杂度，收敛重复的日期时间选择逻辑，并为后续表单扩展与测试留出清晰边界。

## 背景

当前 [`lib/app/add_sheet.dart`](/F:/HarmonyProject/Pet/lib/app/add_sheet.dart) 约 1864 行，混合承载了以下职责：

- `AddActionSheet` 外壳、阶段切换和头部过渡动画
- 动作入口网格与预览卡片
- 待办、提醒、记录、宠物四类表单
- 表单公共壳与无宠物前置提示
- iOS / Material 双平台日期时间选择逻辑
- 宠物引导页嵌入

其中待办、提醒、记录三类表单在日期时间状态维护和选择逻辑上存在显著重复，导致修改点分散，评审成本高，也不利于后续测试。

## 设计原则

- 保持行为等价：不修改现有业务流程、按钮语义、路由返回和存储调用。
- 保持测试稳定：原有 `ValueKey` 字面值必须保留。
- 渐进迁移：优先抽公共能力，再迁移表单，最后收口外壳。
- 范围克制：仅修改 `add_sheet` 直接相关文件和必要测试文件。

## 目标结构

计划将 `add_sheet` 相关代码拆为四层：

### 1. 外壳层

文件：

- `lib/app/add_sheet.dart`
- `lib/app/add_sheet/add_action_sheet_shell.dart`

职责：

- `lib/app/add_sheet.dart` 作为兼容入口，仅对外暴露 `AddActionSheet`。
- `add_action_sheet_shell.dart` 承载 `AddActionSheet`、动画控制器、阶段切换、Header 过渡和不同内容页的装配逻辑。

原因：

- 当前结构测试和潜在外部引用已经依赖 `lib/app/add_sheet.dart`。
- 保留兼容入口可以降低其他调用方改动面，同时允许主体逻辑迁入新文件。

### 2. 表单层

文件：

- `lib/app/add_sheet/forms/todo_form.dart`
- `lib/app/add_sheet/forms/reminder_form.dart`
- `lib/app/add_sheet/forms/record_form.dart`
- `lib/app/add_sheet/forms/pet_form.dart`

职责：

- 每个表单只管理自己的字段状态、提交行为和最少量的视图拼装。
- 保持原有 `PetNoteStore` 调用方式不变。

边界：

- 日期时间选择不再散落在表单内部实现。
- 通用布局、宠物选择和枚举选项展示交由公共控件层处理。

### 3. 公共控件层

文件：

- `lib/app/add_sheet/form_controls/form_scaffold.dart`
- `lib/app/add_sheet/form_controls/adaptive_date_time_field.dart`
- `lib/app/add_sheet/form_controls/pet_selector.dart`
- `lib/app/add_sheet/form_controls/choice_wrap.dart`
- `lib/app/add_sheet/form_controls/missing_pet_prerequisite.dart`

职责：

- `FormScaffold`：统一滚动区、底部提交按钮和安全区处理。
- `AdaptiveDateTimeField`：统一 Android/iOS 日期时间展示与点击入口。
- `PetSelector`：统一宠物选择 UI。
- `ChoiceWrap`：统一枚举类选项展示。
- `MissingPetPrerequisite`：统一无宠物场景提示卡片。

原因：

- 当前 `_ExpandedFormContent`、`_PetSelector`、`_ChoiceWrap` 等已经具备明显的复用属性，继续留在大文件里只会增加耦合。

### 4. 日期时间选择层

文件：

- `lib/app/add_sheet/pickers/date_time_pickers.dart`

职责：

- 收口 `showDatePicker`、`showTimePicker`、`CupertinoDatePicker` 的平台差异。
- 对外暴露统一方法：
  - `pickAdaptiveDateTime`
  - `pickCupertinoDatePart`
  - `pickCupertinoTimePart`
  - `defaultFutureDateTime`
  - `formatIosDateLabel`
  - `formatIosTimeLabel`

原因：

- 当前 `_pickDateTime`、`_pickCupertinoDate`、`_pickCupertinoTime` 和 `_showCupertinoPickerSheet` 高度耦合在主文件中，且被多个表单间接重复包装。

## 关键实现策略

## 表单与日期时间控件的关系

不采用“字段自己持有 `TextEditingController` + 包装三套选择函数”的旧模式，改为：

- 表单只持有 `DateTime value`
- `AdaptiveDateTimeField` 接收：
  - `value`
  - `onChanged`
  - `materialFieldKey`
  - `iosDateFieldKey`
  - `iosTimeFieldKey`
- 选择成功后，控件调用 `onChanged(nextValue)`，表单仅 `setState`

这样可以消除待办、提醒、记录中 6 组重复的包装函数与文本同步逻辑。

## 兼容入口策略

不直接删除现有 [`lib/app/add_sheet.dart`](/F:/HarmonyProject/Pet/lib/app/add_sheet.dart)，而是将其收敛为轻量导出入口，例如：

```dart
export 'add_sheet/add_action_sheet_shell.dart';
```

这样做的好处：

- 避免其他文件引用路径失效
- 结构测试可以继续从原入口出发
- 主实现代码依然能够迁入目录化结构

## 测试策略

必须同步维护 [`test/add_sheet_structure_test.dart`](/F:/HarmonyProject/Pet/test/add_sheet_structure_test.dart)。

原因：

- 该测试当前直接读取 `lib/app/add_sheet.dart` 的源码字符串。
- 模块化后，如果不调整断言来源，测试将失去真实性。

测试调整方向：

- 保持入口文件存在的断言不变。
- 将与动画和布局实现直接相关的源码字符串断言，迁移为读取 `lib/app/add_sheet/add_action_sheet_shell.dart`。
- 保留对关键标识符与 `ValueKey` 的结构性验证。

## 风险与控制

### 风险 1：结构测试失真

控制：

- 同步更新 `test/add_sheet_structure_test.dart` 的读取路径和断言来源。

### 风险 2：`ValueKey` 丢失导致自动化回归失败

控制：

- 明确把所有现有 Key 字面值视为兼容契约，迁移时原样保留。

### 风险 3：日期时间交互行为偏移

控制：

- 保持 iOS 仍分日期/时间两行入口。
- 保持 Android 仍先选日期再选时间。
- 保持“取消后值不变”的现有行为。

### 风险 4：范围膨胀

控制：

- 第一轮不引入新的表单基类、控制器抽象或状态管理重写。
- 仅完成职责拆分与重复逻辑收敛。

## 预期结果

重构完成后：

- `AddActionSheet` 外壳与表单逻辑解耦
- 日期时间选择逻辑集中在单独模块
- 三类业务表单结构更短、更可读
- 结构测试仍可验证动画与关键标识
- 后续新增表单时只需组合公共控件与 store 提交逻辑
