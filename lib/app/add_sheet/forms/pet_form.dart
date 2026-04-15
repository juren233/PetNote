import 'package:flutter/material.dart';
import 'package:petnote/app/common_widgets.dart';
import 'package:petnote/state/petnote_store.dart';

import '../form_controls/form_scaffold.dart';

class PetForm extends StatefulWidget {
  const PetForm({super.key, required this.store});

  final PetNoteStore store;

  @override
  State<PetForm> createState() => _PetFormState();
}

class _PetFormState extends State<PetForm> {
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _sex = TextEditingController(text: '未填写');
  final _birthday = TextEditingController(text: '2026-03-24');
  final _weight = TextEditingController(text: '3.5');
  final _feeding = TextEditingController();
  final _allergies = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _sex.dispose();
    _birthday.dispose();
    _weight.dispose();
    _feeding.dispose();
    _allergies.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormShell(
      title: '新增爱宠',
      child: Column(
        children: [
          SectionCard(
            title: '档案信息',
            children: [
              const SectionLabel(text: '名字'),
              HyperTextField(controller: _name),
              const SectionLabel(text: '品种'),
              HyperTextField(controller: _breed),
              const SectionLabel(text: '性别'),
              HyperTextField(controller: _sex),
              const SectionLabel(text: '生日'),
              HyperTextField(controller: _birthday),
              const SectionLabel(text: '体重'),
              HyperTextField(controller: _weight),
              const SectionLabel(text: '喂养偏好'),
              HyperTextField(controller: _feeding, maxLines: 3),
              const SectionLabel(text: '过敏/禁忌'),
              HyperTextField(controller: _allergies, maxLines: 3),
              const SectionLabel(text: '备注'),
              HyperTextField(controller: _note, maxLines: 3),
            ],
          ),
          FilledButton(
            onPressed: () async {
              await widget.store.addPet(
                name: _name.text.trim(),
                type: PetType.other,
                breed: _breed.text.trim(),
                sex: _sex.text.trim(),
                birthday: _birthday.text.trim(),
                weightKg: double.tryParse(_weight.text.trim()) ?? 0,
                neuterStatus: PetNeuterStatus.unknown,
                feedingPreferences: _feeding.text.trim(),
                allergies: _allergies.text.trim(),
                note: _note.text.trim(),
              );
              if (!context.mounted) {
                return;
              }
              Navigator.pop(context);
            },
            child: const Text('保存爱宠'),
          ),
        ],
      ),
    );
  }
}
