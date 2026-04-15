import 'package:flutter/material.dart';
import 'package:petnote/app/common_widgets.dart';

import '../add_sheet_models.dart';

class MissingPetPrerequisite extends StatelessWidget {
  const MissingPetPrerequisite({
    super.key,
    required this.action,
    required this.onAddPet,
  });

  final AddAction action;
  final VoidCallback onAddPet;

  @override
  Widget build(BuildContext context) {
    final message = switch (action) {
      AddAction.todo => '待办需要先关联一只爱宠，建好第一份档案后再安排补货、清洁和轻任务。',
      AddAction.reminder => '提醒需要先关联一只爱宠，建好第一份档案后再安排疫苗、驱虫和复诊。',
      AddAction.record => '记录需要先关联一只爱宠，建好第一份档案后再保存病历、票据和照片。',
      AddAction.pet => '先完成第一只爱宠建档。',
      AddAction.none => '先添加第一只爱宠。',
    };

    return EmptyCard(
      title: '先添加第一只爱宠',
      subtitle: message,
      actionLabel: '开始添加宠物',
      onAction: onAddPet,
    );
  }
}
