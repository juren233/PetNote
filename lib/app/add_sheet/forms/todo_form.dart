import 'package:flutter/material.dart';
import 'package:petnote/app/common_widgets.dart';
import 'package:petnote/state/petnote_store.dart';

import '../form_controls/adaptive_date_time_field.dart';
import '../form_controls/choice_wrap.dart';
import '../form_controls/form_scaffold.dart';
import '../form_controls/pet_selector.dart';
import '../pickers/date_time_pickers.dart';

class TodoForm extends StatefulWidget {
  const TodoForm({super.key, required this.store});

  final PetNoteStore store;

  @override
  State<TodoForm> createState() => _TodoFormState();
}

class _TodoFormState extends State<TodoForm> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  late String _petId;
  late DateTime _dueAt;
  NotificationLeadTime _notificationLeadTime = NotificationLeadTime.none;

  @override
  void initState() {
    super.initState();
    _petId = widget.store.pets.first.id;
    _dueAt = defaultFutureDateTime();
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      actionLabel: '保存待办',
      actionColor: const Color(0xFF4F7BFF),
      onSubmit: () async {
        await widget.store.addTodo(
          title: _title.text.trim(),
          petId: _petId,
          dueAt: _dueAt,
          notificationLeadTime: _notificationLeadTime,
          note: _note.text.trim(),
        );
        if (!context.mounted) {
          return;
        }
        Navigator.pop(context);
      },
      child: SectionCard(
        title: '基础信息',
        children: [
          const SectionLabel(text: '标题'),
          HyperTextField(controller: _title, hintText: '例如：补货主粮'),
          const SectionLabel(text: '关联爱宠'),
          PetSelector(
            pets: widget.store.pets,
            value: _petId,
            onChanged: (value) => setState(() => _petId = value),
          ),
          const SectionLabel(text: '时间'),
          AdaptiveDateTimeField(
            materialFieldKey: const ValueKey('todo_due_at_field'),
            iosDateFieldKey: const ValueKey('todo_due_date_field'),
            iosTimeFieldKey: const ValueKey('todo_due_time_field'),
            value: _dueAt,
            onChanged: (value) => setState(() => _dueAt = value),
          ),
          const SectionLabel(text: '提前通知'),
          ChoiceWrap<NotificationLeadTime>(
            values: NotificationLeadTime.values,
            selected: _notificationLeadTime,
            labelBuilder: notificationLeadTimeLabel,
            onChanged: (value) => setState(() => _notificationLeadTime = value),
          ),
          const SectionLabel(text: '备注'),
          HyperTextField(controller: _note, hintText: '记录一下补货偏好', maxLines: 3),
        ],
      ),
    );
  }
}
