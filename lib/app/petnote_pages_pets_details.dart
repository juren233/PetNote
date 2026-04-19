part of 'petnote_pages.dart';

class PetDetailsPage extends StatelessWidget {
  const PetDetailsPage({
    super.key,
    required this.pet,
    required this.reminders,
    required this.records,
    required this.detailType,
  });

  final Pet pet;
  final List<ReminderItem> reminders;
  final List<PetRecord> records;
  final PetDetailType detailType;

  @override
  Widget build(BuildContext context) {
    const pagePadding = EdgeInsets.fromLTRB(18, 8, 18, 20);

    return Scaffold(
      appBar: AppBar(
        title: Text(detailType == PetDetailType.reminders ? '近期提醒' : '资料记录'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: pagePadding,
        children: [
          PageHeader(
            title: pet.name,
            subtitle:
                '${petTypeLabel(pet.type)} · ${pet.breed} · ${pet.ageLabel}',
          ),
          const SizedBox(height: 8),
          if (detailType == PetDetailType.reminders)
            _buildRemindersSection(context, reminders)
          else
            _buildRecordsSection(context, records),
        ],
      ),
    );
  }

  Widget _buildRemindersSection(
    BuildContext context,
    List<ReminderItem> reminders,
  ) {
    if (reminders.isEmpty) {
      return PageEmptyStateBlock(
        emptyTitle: '暂无提醒',
        emptySubtitle: '当前宠物暂无任何提醒记录。',
        actionLabel: '返回',
        onAction: () => Navigator.pop(context),
      );
    }

    return SectionCard(
      title: '近期提醒',
      children: reminders
          .map(
            (item) => StatusListRow(
              key: ValueKey('pet-reminder-row-${item.id}'),
              title: item.title,
              subtitle: '${formatDate(item.scheduledAt)} · ${item.recurrence}',
              leadingIcon: Icons.notifications_active_rounded,
              leadingBackgroundColor: const Color(0xFFFFF1DD),
              leadingIconColor: const Color(0xFFF2A65A),
              trailing: HyperBadge(
                text: _reminderKindLabel(item.kind),
                foreground: const Color(0xFFC57A14),
                background: const Color(0xFFFFF1DD),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => _ReminderDetailPage(
                      pet: pet,
                      reminder: item,
                    ),
                  ),
                );
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildRecordsSection(BuildContext context, List<PetRecord> records) {
    if (records.isEmpty) {
      return PageEmptyStateBlock(
        emptyTitle: '暂无资料记录',
        emptySubtitle: '当前宠物暂无任何资料记录。',
        actionLabel: '返回',
        onAction: () => Navigator.pop(context),
      );
    }

    return SectionCard(
      title: '资料记录',
      children: records
          .map(
            (item) => StatusListRow(
              key: ValueKey('pet-record-row-${item.id}'),
              title: item.title,
              subtitle: _recordSubtitle(item),
              leadingIcon: Icons.description_rounded,
              leadingBackgroundColor: const Color(0xFFE8F7EE),
              leadingIconColor: const Color(0xFF4FB57C),
              leading: _RecordListLeading(record: item),
              trailing: HyperBadge(
                text: _recordPurposeLabel(
                  item.purpose,
                  customPurposeLabel: item.customPurposeLabel,
                ),
                foreground: const Color(0xFF2F8F5B),
                background: const Color(0xFFE8F7EE),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => _RecordDetailPage(
                      pet: pet,
                      record: item,
                    ),
                  ),
                );
              },
            ),
          )
          .toList(),
    );
  }

  String _recordSubtitle(PetRecord item) {
    final segments = <String>[
      formatDate(item.recordDate, withTime: false),
      _recordTypeLabel(item.type),
      if (item.summary.trim().isNotEmpty) item.summary.trim(),
    ];
    return segments.join(' · ');
  }

  static String _reminderKindLabel(ReminderKind kind) {
    switch (kind) {
      case ReminderKind.medication:
        return '用药';
      case ReminderKind.review:
        return '就诊';
      case ReminderKind.vaccine:
        return '疫苗';
      case ReminderKind.grooming:
        return '美容';
      case ReminderKind.deworming:
        return '驱虫';
      case ReminderKind.custom:
        return '其他';
    }
  }

  static String _reminderStatusLabel(ReminderStatus status) {
    switch (status) {
      case ReminderStatus.pending:
        return '待处理';
      case ReminderStatus.done:
        return '已完成';
      case ReminderStatus.skipped:
        return '已跳过';
      case ReminderStatus.postponed:
        return '已延后';
      case ReminderStatus.overdue:
        return '已逾期';
    }
  }

  static String _recordTypeLabel(PetRecordType type) {
    switch (type) {
      case PetRecordType.medical:
        return '就诊';
      case PetRecordType.testResult:
        return '检查';
      case PetRecordType.receipt:
        return '收据';
      case PetRecordType.image:
        return '图片';
      case PetRecordType.other:
        return '其他';
    }
  }

  static String _recordPurposeLabel(
    RecordPurpose? purpose, {
    String? customPurposeLabel,
  }) {
    final customLabel = customPurposeLabel?.trim();
    switch (purpose) {
      case RecordPurpose.health:
        return '健康';
      case RecordPurpose.life:
        return '生活';
      case RecordPurpose.expense:
        return '消费';
      case RecordPurpose.other:
        return customLabel?.isNotEmpty ?? false ? customLabel! : '其他';
      case null:
        return '未分类';
    }
  }
}

class _ReminderDetailPage extends StatelessWidget {
  const _ReminderDetailPage({
    required this.pet,
    required this.reminder,
  });

  final Pet pet;
  final ReminderItem reminder;

  @override
  Widget build(BuildContext context) {
    const pagePadding = EdgeInsets.fromLTRB(18, 8, 18, 20);
    return Scaffold(
      key: ValueKey('pet-reminder-detail-page-${reminder.id}'),
      appBar: AppBar(
        title: const Text('提醒详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: pagePadding,
        children: [
          PageHeader(
            title: reminder.title,
            subtitle:
                '${pet.name} · ${PetDetailsPage._reminderKindLabel(reminder.kind)}',
          ),
          HeroPanel(
            title: '下次提醒时间',
            subtitle:
                '${formatDate(reminder.scheduledAt)} · ${notificationLeadTimeLabel(reminder.notificationLeadTime)}',
            child: HyperBadge(
              text: PetDetailsPage._reminderStatusLabel(reminder.status),
              foreground: const Color(0xFFC57A14),
              background: const Color(0xFFFFF1DD),
            ),
          ),
          SectionCard(
            title: '提醒信息',
            children: [
              InfoRow(
                label: '提醒类型',
                value: PetDetailsPage._reminderKindLabel(reminder.kind),
              ),
              InfoRow(
                label: '提醒时间',
                value: formatDate(reminder.scheduledAt),
              ),
              InfoRow(label: '重复频率', value: reminder.recurrence),
              InfoRow(
                label: '提前通知',
                value: notificationLeadTimeLabel(reminder.notificationLeadTime),
              ),
              InfoRow(
                label: '当前状态',
                value: PetDetailsPage._reminderStatusLabel(reminder.status),
              ),
            ],
          ),
          if (reminder.note.trim().isNotEmpty)
            SectionCard(
              title: '提醒备注',
              children: [
                Text(
                  reminder.note.trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RecordDetailPage extends StatelessWidget {
  const _RecordDetailPage({
    required this.pet,
    required this.record,
  });

  final Pet pet;
  final PetRecord record;

  @override
  Widget build(BuildContext context) {
    const pagePadding = EdgeInsets.fromLTRB(18, 8, 18, 20);
    return Scaffold(
      key: ValueKey('pet-record-detail-page-${record.id}'),
      appBar: AppBar(
        title: const Text('记录详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: pagePadding,
        children: [
          PageHeader(
            title: record.title,
            subtitle:
                '${pet.name} · ${PetDetailsPage._recordTypeLabel(record.type)}',
          ),
          HeroPanel(
            title: '记录概览',
            subtitle: _recordHeroSubtitle(record),
            child: HyperBadge(
              text: PetDetailsPage._recordPurposeLabel(
                record.purpose,
                customPurposeLabel: record.customPurposeLabel,
              ),
              foreground: const Color(0xFF2F8F5B),
              background: const Color(0xFFE8F7EE),
            ),
          ),
          if (record.photoPaths.isNotEmpty)
            SectionCard(
              title: '记录图片',
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: record.photoPaths
                      .map(
                        (path) => _RecordDetailPhotoTile(
                          photoPaths: record.photoPaths,
                          initialIndex: record.photoPaths.indexOf(path),
                          photoPath: path,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          SectionCard(
            title: '记录信息',
            children: [
              InfoRow(
                label: '记录日期',
                value: formatDate(record.recordDate),
              ),
              InfoRow(
                label: '记录类型',
                value: PetDetailsPage._recordTypeLabel(record.type),
              ),
              InfoRow(
                label: '记录用途',
                value: PetDetailsPage._recordPurposeLabel(
                  record.purpose,
                  customPurposeLabel: record.customPurposeLabel,
                ),
              ),
            ],
          ),
          if (record.summary.trim().isNotEmpty)
            SectionCard(
              title: '记录正文',
              children: [
                Text(
                  record.summary.trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                ),
              ],
            ),
          if (record.note.trim().isNotEmpty)
            SectionCard(
              title: '补充备注',
              children: [
                Text(
                  record.note.trim(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _recordHeroSubtitle(PetRecord item) {
    final segments = <String>[
      formatDate(item.recordDate, withTime: false),
      PetDetailsPage._recordTypeLabel(item.type),
      if (item.photoPaths.isNotEmpty) '${item.photoPaths.length} 张图片',
    ];
    return segments.join(' · ');
  }
}

class _RecordDetailPhotoTile extends StatelessWidget {
  const _RecordDetailPhotoTile({
    required this.photoPaths,
    required this.initialIndex,
    required this.photoPath,
  });

  final List<String> photoPaths;
  final int initialIndex;
  final String photoPath;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('pet-record-detail-photo-tile-$photoPath'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showRecordPhotoPreview(
          context,
          photoPaths,
          initialIndex,
        ),
        child: PetPhotoSquare(
          key: ValueKey('pet-record-detail-photo-$photoPath'),
          photoPath: photoPath,
          size: 96,
          borderRadius: BorderRadius.circular(18),
          fallback: _buildRecordIconFallback(),
        ),
      ),
    );
  }
}

class _RecordListLeading extends StatelessWidget {
  const _RecordListLeading({
    required this.record,
  });

  final PetRecord record;

  @override
  Widget build(BuildContext context) {
    final primaryPhotoPath =
        record.photoPaths.isEmpty ? null : record.photoPaths.first;
    if (primaryPhotoPath == null) {
      return _buildRecordIconFallback();
    }

    return PetPhotoSquare(
      photoPath: primaryPhotoPath,
      size: 42,
      borderRadius: BorderRadius.circular(16),
      fallback: _buildRecordIconFallback(),
    );
  }
}

Future<void> _showRecordPhotoPreview(
  BuildContext context,
  List<String> photoPaths,
  int initialIndex,
) async {
  await showGeneralDialog<void>(
    context: context,
    barrierLabel: '关闭图片预览',
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => _PetPhotoPreviewDialog(
      photoPaths: photoPaths,
      initialIndex: initialIndex,
    ),
    transitionBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.94,
            end: 1.0,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _PetPhotoPreviewDialog extends StatefulWidget {
  const _PetPhotoPreviewDialog({
    required this.photoPaths,
    required this.initialIndex,
  });

  final List<String> photoPaths;
  final int initialIndex;

  @override
  State<_PetPhotoPreviewDialog> createState() => _PetPhotoPreviewDialogState();
}

class _PetPhotoPreviewDialogState extends State<_PetPhotoPreviewDialog> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showPrevious() {
    if (_currentIndex <= 0) {
      return;
    }
    _pageController.animateToPage(
      _currentIndex - 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _showNext() {
    if (_currentIndex >= widget.photoPaths.length - 1) {
      return;
    }
    _pageController.animateToPage(
      _currentIndex + 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final dialogWidth = maxWidth >= 900 ? maxWidth * 0.92 : maxWidth * 0.94;
        final dialogHeight =
            maxHeight >= 900 ? maxHeight * 0.88 : maxHeight * 0.84;
        final showDesktopControls =
            maxWidth >= 900 && widget.photoPaths.length > 1;
        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.arrowLeft): _showPrevious,
            const SingleActivator(LogicalKeyboardKey.arrowRight): _showNext,
            const SingleActivator(LogicalKeyboardKey.escape):
                Navigator.of(context).pop,
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    key: const ValueKey('pet-photo-preview-backdrop'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.84),
                    ),
                  ),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: dialogWidth.clamp(280.0, 1440.0),
                        maxHeight: dialogHeight.clamp(260.0, 1100.0),
                      ),
                      child: Material(
                        key: const ValueKey('pet-photo-preview-dialog'),
                        color: Colors.transparent,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 28, 24, 56),
                                child: PageView.builder(
                                  key: const ValueKey('pet-photo-preview-pager'),
                                  controller: _pageController,
                                  physics: const BouncingScrollPhysics(),
                                  onPageChanged: (value) {
                                    setState(() => _currentIndex = value);
                                  },
                                  itemCount: widget.photoPaths.length,
                                  itemBuilder: (context, index) {
                                    return Center(
                                      child: PetPhotoContainFrame(
                                        photoPath: widget.photoPaths[index],
                                        borderRadius:
                                            BorderRadius.circular(26),
                                        fallback: const Center(
                                          child: Icon(
                                            Icons.broken_image_rounded,
                                            size: 36,
                                            color: Color(0xFFB8BEC8),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton.filledTonal(
                                key: const ValueKey(
                                  'pet-photo-preview-close-button',
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.14),
                                  foregroundColor:
                                      Colors.white.withValues(alpha: 0.94),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Center(
                                child: Container(
                                  key: const ValueKey(
                                    'pet-photo-preview-index-indicator',
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${_currentIndex + 1} / ${widget.photoPaths.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.82),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            if (showDesktopControls)
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                child: _PreviewNavButton(
                                  key: const ValueKey(
                                    'pet-photo-preview-previous-button',
                                  ),
                                  icon: Icons.chevron_left_rounded,
                                  enabled: _currentIndex > 0,
                                  onTap: _showPrevious,
                                ),
                              ),
                            if (showDesktopControls)
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: _PreviewNavButton(
                                  key: const ValueKey(
                                    'pet-photo-preview-next-button',
                                  ),
                                  icon: Icons.chevron_right_rounded,
                                  enabled: _currentIndex <
                                      widget.photoPaths.length - 1,
                                  onTap: _showNext,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreviewNavButton extends StatelessWidget {
  const _PreviewNavButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: IconButton.filled(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
            foregroundColor: Colors.white.withValues(alpha: 0.92),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.28),
          ),
        ),
      ),
    );
  }
}

Widget _buildRecordIconFallback() {
  return Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: const Color(0xFFE8F7EE),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Center(
      child: Icon(
        Icons.description_rounded,
        color: Color(0xFF4FB57C),
      ),
    ),
  );
}

enum PetDetailType {
  reminders,
  records,
}
