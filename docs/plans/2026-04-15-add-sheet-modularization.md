# Add Sheet Modularization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 `add_sheet` 从单文件多职责结构拆分为外壳、表单、公共控件和日期时间选择模块，同时保持现有交互与关键 `ValueKey` 不变。

**Architecture:** 继续保留 `lib/app/add_sheet.dart` 作为兼容入口，把主体逻辑迁入 `lib/app/add_sheet/` 目录。先抽日期时间能力和公共控件，再迁移表单，最后迁移 `AddActionSheet` 外壳，并同步修正结构测试。

**Tech Stack:** Flutter、Dart、Material/Cupertino 组件、`flutter_test`

---

### Task 1: 建立 add_sheet 目录结构与兼容入口

**Files:**
- Create: `lib/app/add_sheet/add_action_sheet_shell.dart`
- Create: `lib/app/add_sheet/forms/`
- Create: `lib/app/add_sheet/form_controls/`
- Create: `lib/app/add_sheet/pickers/`
- Modify: `lib/app/add_sheet.dart`

**Step 1: 建立失败前提**

记录当前入口依赖和结构测试行为，确认 `test/add_sheet_structure_test.dart` 当前直接读取 `lib/app/add_sheet.dart`。

**Step 2: 修改入口文件**

将 `lib/app/add_sheet.dart` 收敛为兼容入口，导出新的外壳实现文件。

**Step 3: 运行结构测试**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: 先失败或暴露读取来源需要更新的问题。

**Step 4: 记录迁移点**

确认后续需要把哪些源码断言迁到新外壳文件。

### Task 2: 抽取日期时间选择能力

**Files:**
- Create: `lib/app/add_sheet/pickers/date_time_pickers.dart`
- Modify: `lib/app/add_sheet.dart` 或 `lib/app/add_sheet/add_action_sheet_shell.dart`

**Step 1: 写最小结构测试补充**

在 `test/add_sheet_structure_test.dart` 或新增相关测试中验证新 picker 模块被引用，且 `AddActionSheet` 仍保留原有关键方法链路。

**Step 2: 运行测试确认失败**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: FAIL，因新模块尚未建立或断言未满足。

**Step 3: 实现最小 picker 模块**

迁移以下函数：

- `defaultFutureDateTime`
- `pickAdaptiveDateTime`
- `pickCupertinoDatePart`
- `pickCupertinoTimePart`
- `showCupertinoPickerSheet`
- `formatIosDateLabel`
- `formatIosTimeLabel`

**Step 4: 运行测试确认通过**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: PASS 或只剩后续迁移导致的预期失败。

### Task 3: 抽取公共控件

**Files:**
- Create: `lib/app/add_sheet/form_controls/form_scaffold.dart`
- Create: `lib/app/add_sheet/form_controls/adaptive_date_time_field.dart`
- Create: `lib/app/add_sheet/form_controls/pet_selector.dart`
- Create: `lib/app/add_sheet/form_controls/choice_wrap.dart`
- Create: `lib/app/add_sheet/form_controls/missing_pet_prerequisite.dart`
- Modify: `lib/app/add_sheet/add_action_sheet_shell.dart`

**Step 1: 写结构性验证**

补充或调整测试，验证以下兼容项仍存在：

- `todo_due_at_field`
- `todo_due_date_field`
- `todo_due_time_field`
- `reminder_scheduled_at_field`
- `record_date_field`

**Step 2: 运行测试确认失败**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: FAIL，因控件尚未迁移。

**Step 3: 实现最小公共控件**

将现有 `_ExpandedFormContent`、`_PetSelector`、`_ChoiceWrap`、`_MissingPetPrerequisite`、`_AdaptiveDateTimeField` 迁出，并保持视觉和键值兼容。

**Step 4: 运行测试确认通过**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: PASS 或只剩表单迁移相关失败。

### Task 4: 迁移 Todo 与 Reminder 表单

**Files:**
- Create: `lib/app/add_sheet/forms/todo_form.dart`
- Create: `lib/app/add_sheet/forms/reminder_form.dart`
- Modify: `lib/app/add_sheet/add_action_sheet_shell.dart`

**Step 1: 写针对性结构验证**

在 `test/add_sheet_structure_test.dart` 中确保外壳仍通过相同动作枚举路由到待办/提醒表单。

**Step 2: 运行测试确认失败**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: FAIL，因新表单尚未接线。

**Step 3: 实现最小迁移**

- 保留 `PetNoteStore` 调用不变
- 删除重复的日期时间包装函数
- 改为 `AdaptiveDateTimeField(value, onChanged)` 模式

**Step 4: 运行测试确认通过**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: PASS

### Task 5: 迁移 Record 与 Pet 表单

**Files:**
- Create: `lib/app/add_sheet/forms/record_form.dart`
- Create: `lib/app/add_sheet/forms/pet_form.dart`
- Modify: `lib/app/add_sheet/add_action_sheet_shell.dart`

**Step 1: 写针对性结构验证**

确保 record / pet 路由和无宠物前置条件分支仍存在。

**Step 2: 运行测试确认失败**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: FAIL，因表单尚未迁移完毕。

**Step 3: 实现最小迁移**

迁移表单，不改变提交流程和 `Navigator.pop` 时机。

**Step 4: 运行测试确认通过**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: PASS

### Task 6: 迁移 AddActionSheet 外壳

**Files:**
- Modify: `lib/app/add_sheet/add_action_sheet_shell.dart`
- Modify: `lib/app/add_sheet.dart`
- Modify: `test/add_sheet_structure_test.dart`

**Step 1: 写结构测试调整**

将直接依赖源码字符串的断言更新为从真正承载动画逻辑的文件读取。

**Step 2: 运行测试确认失败**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: FAIL，因路径与断言来源尚未完全对齐。

**Step 3: 完成外壳迁移**

迁移以下内容到新外壳文件：

- `AddActionSheet`
- `_AddSheetStage`
- 动画控制器与折叠逻辑
- Header 过渡相关组件
- 动作入口网格和预览卡片

**Step 4: 运行测试确认通过**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: PASS

### Task 7: 全量回归验证

**Files:**
- Modify: 仅限前述直接相关文件
- Test: `test/add_sheet_structure_test.dart`

**Step 1: 运行结构测试**

Run: `flutter test test/add_sheet_structure_test.dart`

Expected: PASS

**Step 2: 运行主应用关键测试**

Run: `flutter test test/widget_test.dart`

Expected: PASS

**Step 3: 运行构建验证**

Run: `flutter analyze`

Expected: 无新增错误。

**Step 4: 检查工作区**

Run: `git status --short`

Expected: 仅出现 `add_sheet` 相关文件与必要测试文件变更。

**Step 5: 提交说明**

本轮默认不提交，除非用户明确要求。
