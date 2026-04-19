import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final rootSource = File('lib/app/petnote_root.dart').readAsStringSync();
  final addSheetEntrySource = File('lib/app/add_sheet.dart').readAsStringSync();
  final sheetSource =
      File('lib/app/add_sheet/add_action_sheet_shell.dart').readAsStringSync();
  final todoFormSource =
      File('lib/app/add_sheet/forms/todo_form.dart').readAsStringSync();
  final reminderFormSource =
      File('lib/app/add_sheet/forms/reminder_form.dart').readAsStringSync();
  final recordFormSource =
      File('lib/app/add_sheet/forms/record_form.dart').readAsStringSync();
  final petEditSheetSource =
      File('lib/app/pet_edit_sheet.dart').readAsStringSync();

  test(
      'add sheet relies on the system drag handle instead of rendering a duplicate one',
      () {
    expect(rootSource, contains('showDragHandle: true'));
    expect(sheetSource, isNot(contains('height: 5,')));
  });

  test(
      'pet edit sheet relies on the system drag handle instead of rendering a duplicate one',
      () {
    expect(rootSource, contains('showDragHandle: true'));
    expect(petEditSheetSource, isNot(contains('width: 52,')));
    expect(petEditSheetSource, isNot(contains('height: 5,')));
  });

  test(
      'add sheet avoids default close text and reuses one transition controller for collapse',
      () {
    expect(
      addSheetEntrySource,
      contains("export 'add_sheet/add_action_sheet_shell.dart';"),
    );
    expect(
      sheetSource,
      isNot(contains("child: Text(_action == AddAction.none ? '关闭' : '返回')")),
    );
    expect(sheetSource, isNot(contains('AnimatedSwitcher(')));
    expect(sheetSource, isNot(contains('enum _CollapsePhase')));
    expect(sheetSource, isNot(contains('_collapseContentController')));
    expect(sheetSource, contains('_transitionController.reverse('));
    expect(sheetSource,
        contains('status == AnimationStatus.dismissed && _isCollapsing'));
    expect(sheetSource, contains('_actionsRevealStart'));
    expect(sheetSource, contains('_actionsRevealOpacity'));
    expect(sheetSource, contains('_buildActionsContent('));
    expect(sheetSource, contains('_buildHeaderTransition('));
    expect(sheetSource, contains('add_sheet_header_transition'));
    expect(sheetSource, contains('add_sheet_actions_header_transition'));
    expect(sheetSource, contains('add_sheet_expanded_header_transition'));
    expect(sheetSource, contains('_ActionGridPreview'));
    expect(sheetSource, contains('ClipRect('));
    expect(sheetSource, contains('NeverScrollableScrollPhysics()'));
    expect(sheetSource, contains('add_sheet_actions_content'));
    expect(sheetSource, contains('add_sheet_actions_reveal_opacity'));
    expect(sheetSource, isNot(contains('add_sheet_actions_header_reveal')));
    expect(sheetSource, isNot(contains('add_sheet_push_back_layer')));
    expect(sheetSource, isNot(contains('add_sheet_foreground_scale')));
    expect(sheetSource, contains('_petOnboardingTopPadding'));
    expect(sheetSource, contains('_sheetTopPadding'));
  });

  test('add forms no longer expose manual key metrics editors', () {
    for (final source in [
      todoFormSource,
      reminderFormSource,
      recordFormSource
    ]) {
      expect(source, isNot(contains('MeasurementEditorSection')));
      expect(source, isNot(contains('MeasurementDraft')));
      expect(source, isNot(contains('关键指标')));
      expect(source, isNot(contains('新增指标')));
    }
  });

  test(
      'todo and reminder forms use simplified core fields instead of semantic controls',
      () {
    for (final source in [todoFormSource, reminderFormSource]) {
      expect(source, isNot(contains("SectionLabel(text: '主题')")));
      expect(source, isNot(contains("SectionLabel(text: '执行意图')")));
      expect(source, isNot(contains("SectionLabel(text: '跟进时间（可选）')")));
      expect(source, isNot(contains('OptionalAdaptiveDateTimeField(')));
      expect(source, isNot(contains('ChoiceWrap<SemanticTopicKey>(')));
      expect(source, isNot(contains('ChoiceWrap<SemanticActionIntent>(')));
    }
    expect(todoFormSource, contains("SectionLabel(text: '标题')"));
    expect(todoFormSource, contains("SectionLabel(text: '关联爱宠')"));
    expect(todoFormSource, contains("SectionLabel(text: '时间')"));
    expect(todoFormSource, contains("SectionLabel(text: '提前通知')"));
    expect(todoFormSource, contains("SectionLabel(text: '补充说明')"));
    expect(reminderFormSource, contains("SectionLabel(text: '标题')"));
    expect(reminderFormSource, contains("SectionLabel(text: '关联爱宠')"));
    expect(reminderFormSource, contains("SectionLabel(text: '时间')"));
    expect(reminderFormSource, contains("SectionLabel(text: '提前通知')"));
    expect(reminderFormSource, isNot(contains("SectionLabel(text: '重复规则')")));
    expect(reminderFormSource, contains("SectionLabel(text: '补充说明')"));
    expect(reminderFormSource, contains('NotificationLeadTime.threeDays'));
    expect(reminderFormSource, contains('NotificationLeadTime.sevenDays'));
  });

  test(
      'record form uses simplified record purpose instead of semantic controls',
      () {
    expect(recordFormSource, contains('RecordPurpose'));
    expect(recordFormSource, contains('健康'));
    expect(recordFormSource, contains('生活'));
    expect(recordFormSource, contains('消费'));
    expect(recordFormSource, contains('其他'));
    expect(recordFormSource, contains('record_summary_field'));
    expect(recordFormSource, contains('record_custom_purpose_field'));
    expect(recordFormSource, isNot(contains('record_note_field')));
    expect(recordFormSource, isNot(contains("SectionLabel(text: '事实正文')")));
    expect(recordFormSource, contains('record_add_photo_hero_card'));
    expect(recordFormSource, contains('record_add_photo_tail_card'));
    expect(recordFormSource, contains('record_add_photo_transition_card'));
    expect(recordFormSource, contains('record_photo_strip'));
    expect(recordFormSource, isNot(contains("SectionLabel(text: '记录类型')")));
    expect(recordFormSource, isNot(contains("SectionLabel(text: '主题')")));
    expect(recordFormSource, isNot(contains("SectionLabel(text: '事件信号')")));
    expect(recordFormSource, isNot(contains("SectionLabel(text: '证据来源')")));
    expect(recordFormSource, isNot(contains('recordSourceOptions')));
    expect(recordFormSource, isNot(contains('recordSignalOptions')));
    expect(recordFormSource, isNot(contains('recordTopicOptions')));
  });
}
