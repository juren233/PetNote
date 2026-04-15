import 'package:flutter/material.dart';
import 'package:petnote/app/common_widgets.dart';
import 'package:petnote/state/petnote_store.dart';

import '../form_controls/adaptive_date_time_field.dart';
import '../form_controls/choice_wrap.dart';
import '../form_controls/form_scaffold.dart';
import '../form_controls/pet_selector.dart';
import '../pickers/date_time_pickers.dart';

class ReminderForm extends StatefulWidget {
  const ReminderForm({super.key, required this.store});

  final PetNoteStore store;

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _recurrence = TextEditingController(text: '单次');
  late String _petId;
  ReminderKind _kind = ReminderKind.custom;
  late DateTime _scheduledAt;
  NotificationLeadTime _notificationLeadTime = NotificationLeadTime.none;

  @override
  void initState() {
    super.initState();
    _petId = widget.store.pets.first.id;
    _scheduledAt = defaultFutureDateTime();
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _recurrence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      actionLabel: '保存提醒',
      actionColor: const Color(0xFFF2A65A),
      onSubmit: () async {
        await widget.store.addReminder(
          title: _title.text.trim(),
          petId: _petId,
          scheduledAt: _scheduledAt,
          notificationLeadTime: _notificationLeadTime,
          kind: _kind,
          recurrence: _recurrence.text.trim(),
          note: _note.text.trim(),
        );
        if (!context.mounted) {
          return;
        }
        Navigator.pop(context);
      },
      child: SectionCard(
        title: '提醒信息',
        children: [
          const SectionLabel(text: '标题'),
          HyperTextField(controller: _title, hintText: '例如：体内驱虫'),
          const SectionLabel(text: '关联爱宠'),
          PetSelector(
            pets: widget.store.pets,
            value: _petId,
            onChanged: (value) => setState(() => _petId = value),
          ),
          const SectionLabel(text: '提醒类型'),
          ChoiceWrap<ReminderKind>(
            values: ReminderKind.values,
            selected: _kind,
            labelBuilder: _reminderKindLabel,
            onChanged: (value) => setState(() => _kind = value),
          ),
          const SectionLabel(text: '时间'),
          AdaptiveDateTimeField(
            materialFieldKey: const ValueKey('reminder_scheduled_at_field'),
            iosDateFieldKey: const ValueKey('reminder_scheduled_date_field'),
            iosTimeFieldKey: const ValueKey('reminder_scheduled_time_field'),
            value: _scheduledAt,
            onChanged: (value) => setState(() => _scheduledAt = value),
          ),
          const SectionLabel(text: '提前通知'),
          ChoiceWrap<NotificationLeadTime>(
            values: NotificationLeadTime.values,
            selected: _notificationLeadTime,
            labelBuilder: notificationLeadTimeLabel,
            onChanged: (value) => setState(() => _notificationLeadTime = value),
          ),
          const SectionLabel(text: '重复规则'),
          HyperTextField(controller: _recurrence),
          const SectionLabel(text: '备注'),
          HyperTextField(controller: _note, maxLines: 3),
        ],
      ),
    );
  }
}

String _reminderKindLabel(ReminderKind kind) => switch (kind) {
      ReminderKind.vaccine => '疫苗',
      ReminderKind.deworming => '驱虫',
      ReminderKind.medication => '用药',
      ReminderKind.review => '复诊',
      ReminderKind.grooming => '洗护',
      ReminderKind.custom => '自定义',
    };
