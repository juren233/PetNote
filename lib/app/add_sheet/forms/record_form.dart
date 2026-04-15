import 'package:flutter/material.dart';
import 'package:petnote/app/common_widgets.dart';
import 'package:petnote/state/petnote_store.dart';

import '../form_controls/adaptive_date_time_field.dart';
import '../form_controls/choice_wrap.dart';
import '../form_controls/form_scaffold.dart';
import '../form_controls/pet_selector.dart';

class RecordForm extends StatefulWidget {
  const RecordForm({super.key, required this.store});

  final PetNoteStore store;

  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _note = TextEditingController();
  late String _petId;
  PetRecordType _type = PetRecordType.other;
  late DateTime _recordDate;

  @override
  void initState() {
    super.initState();
    _petId = widget.store.pets.first.id;
    _recordDate = DateTime.now();
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      actionLabel: '保存记录',
      actionColor: const Color(0xFF4FB57C),
      onSubmit: () async {
        await widget.store.addRecord(
          petId: _petId,
          type: _type,
          title: _title.text.trim(),
          recordDate: _recordDate,
          summary: _summary.text.trim(),
          note: _note.text.trim(),
        );
        if (!context.mounted) {
          return;
        }
        Navigator.pop(context);
      },
      child: SectionCard(
        title: '资料信息',
        children: [
          const SectionLabel(text: '关联爱宠'),
          PetSelector(
            pets: widget.store.pets,
            value: _petId,
            onChanged: (value) => setState(() => _petId = value),
          ),
          const SectionLabel(text: '记录类型'),
          ChoiceWrap<PetRecordType>(
            values: PetRecordType.values,
            selected: _type,
            labelBuilder: _recordTypeLabel,
            onChanged: (value) => setState(() => _type = value),
          ),
          const SectionLabel(text: '标题'),
          HyperTextField(controller: _title, hintText: '例如：体检结果'),
          const SectionLabel(text: '时间'),
          AdaptiveDateTimeField(
            materialFieldKey: const ValueKey('record_date_field'),
            iosDateFieldKey: const ValueKey('record_date_date_field'),
            iosTimeFieldKey: const ValueKey('record_date_time_field'),
            value: _recordDate,
            onChanged: (value) => setState(() => _recordDate = value),
          ),
          const SectionLabel(text: '摘要'),
          HyperTextField(controller: _summary, maxLines: 3),
          const SectionLabel(text: '备注'),
          HyperTextField(controller: _note, maxLines: 3),
        ],
      ),
    );
  }
}

String _recordTypeLabel(PetRecordType type) => switch (type) {
      PetRecordType.medical => '病历',
      PetRecordType.receipt => '票据',
      PetRecordType.image => '图片',
      PetRecordType.testResult => '检查结果',
      PetRecordType.other => '其他',
    };
