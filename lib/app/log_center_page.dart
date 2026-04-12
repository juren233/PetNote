import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petnote/app/app_theme.dart';
import 'package:petnote/app/common_widgets.dart';
import 'package:petnote/logging/app_log_controller.dart';

class LogCenterPage extends StatefulWidget {
  const LogCenterPage({
    super.key,
    required this.controller,
  });

  final AppLogController controller;

  @override
  State<LogCenterPage> createState() => _LogCenterPageState();
}

class _LogCenterPageState extends State<LogCenterPage> {
  AppLogCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final entries = _selectedCategory == null
            ? widget.controller.entries
            : widget.controller.entries
                .where((item) => item.category == _selectedCategory)
                .toList(growable: false);
        final crashStatus = widget.controller.crashDiagnosticsStatus;
        return Scaffold(
          appBar: AppBar(
            title: const Text('日志中心'),
            actions: [
              TextButton(
                onPressed: entries.isEmpty
                    ? null
                    : () => _copyLogs(context, category: _selectedCategory),
                child: const Text('复制'),
              ),
              TextButton(
                onPressed: widget.controller.isEmpty
                    ? null
                    : () => _clearLogs(context),
                child: const Text('清空'),
              ),
            ],
          ),
          body: HyperPageBackground(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                HeroPanel(
                  title: '本地日志中心',
                  subtitle: '统一查看 AI、数据与存储、原生桥接、通知和异常退出线索，方便复制给我排查。',
                  child: Text(
                    '当前共 ${widget.controller.entries.length} 条日志，异常退出线索 ${crashStatus.diagnosticEntryCount} 条',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.petNoteTokens.secondaryText,
                          height: 1.5,
                        ),
                  ),
                ),
                SectionCard(
                  title: '异常退出线索',
                  children: [
                    ListRow(
                      title: crashStatus.hasSuspectedAbnormalExit
                          ? '最近检测到疑似异常退出'
                          : '最近未检测到疑似异常退出',
                      subtitle: crashStatus.hasSuspectedAbnormalExit
                          ? '上次会话没有留下正常结束标记，这通常意味着闪退、异常终止，或系统直接回收了进程。'
                          : '当前没有发现未清理会话标记，但这并不等于已经覆盖了所有系统级闪退场景。',
                    ),
                    ListRow(
                      title: crashStatus.unhandledExceptionCount > 0
                          ? '存在未处理异常记录'
                          : '暂未记录未处理异常',
                      subtitle: crashStatus.unhandledExceptionCount > 0
                          ? '最近一次线索：${crashStatus.latestSignalTitle ?? '未知异常'}'
                          : '当 Dart / Flutter 出现未捕获异常时，这里会同步显示对应条目。',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const SectionCard(
                  title: '系统闪退日志查看指引',
                  children: [
                    ListRow(
                      title: '当前版本不会自动解析原生 crash report',
                      subtitle:
                          '日志中心只展示本地异常退出线索。如果是 iOS 原生层闪退，还需要结合系统 crash report 一起看。',
                    ),
                    ListRow(
                      title: 'iOS 模拟器 / macOS 本地报告',
                      subtitle:
                          '可以先查看 ~/Library/Logs/DiagnosticReports/，或通过 Xcode 的 Devices and Simulators / Console 导出对应进程日志。',
                    ),
                    ListRow(
                      title: 'iPhone 真机报告',
                      subtitle:
                          '可在“设置 > 隐私与安全性 > 分析与改进 > 分析数据”中查看，或使用 Xcode 连接设备后导出崩溃报告。',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SectionCard(
                  title: '分类筛选',
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ChoiceChip(
                          label: const Text('全部'),
                          selected: _selectedCategory == null,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategory = null;
                            });
                          },
                        ),
                        ...AppLogCategory.values.map(
                          (category) => ChoiceChip(
                            label: Text(appLogCategoryLabel(category)),
                            selected: _selectedCategory == category,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (entries.isEmpty)
                  const SectionCard(
                    title: '暂无日志',
                    children: [
                      ListRow(
                        title: '当前还没有可展示的日志',
                        subtitle: '执行 AI 测试、导入导出、通知权限请求或原生桥接操作后，这里会开始积累日志。',
                      ),
                    ],
                  )
                else
                  ...entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LogEntryCard(
                        entry: entry,
                        onCopy: () => _copySingleEntry(context, entry),
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

  Future<void> _copyLogs(
    BuildContext context, {
    AppLogCategory? category,
  }) async {
    await Clipboard.setData(
      ClipboardData(
        text: widget.controller.exportText(category: category),
      ),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('日志已复制')),
    );
  }

  Future<void> _copySingleEntry(BuildContext context, AppLogEntry entry) async {
    await Clipboard.setData(
      ClipboardData(
        text: widget.controller.exportText(category: entry.category),
      ),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('该分类日志已复制')),
    );
  }

  Future<void> _clearLogs(BuildContext context) async {
    await widget.controller.clear();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('日志已清空')),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  const _LogEntryCard({
    required this.entry,
    required this.onCopy,
  });

  final AppLogEntry entry;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final levelColor = switch (entry.level) {
      AppLogLevel.info => const Color(0xFF335FCA),
      AppLogLevel.warning => const Color(0xFFC57A14),
      AppLogLevel.error => const Color(0xFFC7533E),
    };
    return SectionCard(
      title: entry.title,
      trailing: TextButton(
        onPressed: onCopy,
        child: const Text('复制'),
      ),
      children: [
        Text(
          '${appLogCategoryLabel(entry.category)} · ${appLogLevelLabel(entry.level)} · ${entry.timestamp.toLocal()}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: levelColor,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          entry.message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.55,
              ),
        ),
        if (entry.details != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              entry.details!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ],
      ],
    );
  }
}
