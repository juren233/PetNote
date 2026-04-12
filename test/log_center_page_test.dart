import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petnote/app/app_theme.dart';
import 'package:petnote/app/log_center_page.dart';
import 'package:petnote/logging/app_log_controller.dart';

void main() {
  testWidgets('filters entries by category and clears local logs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = AppLogController.memory();
    controller.info(
      category: AppLogCategory.ai,
      title: 'AI 日志',
      message: 'AI 总结开始生成。',
    );
    controller.warning(
      category: AppLogCategory.dataStorage,
      title: '数据日志',
      message: '最近一次恢复前已生成快照。',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPetNoteTheme(Brightness.light),
        home: LogCenterPage(controller: controller),
      ),
    );

    expect(find.text('AI 日志'), findsOneWidget);
    expect(find.text('数据日志'), findsOneWidget);

    await tester.tap(find.text('数据与存储'));
    await tester.pumpAndSettle();

    expect(find.text('数据日志'), findsOneWidget);
    expect(find.text('AI 日志'), findsNothing);

    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();

    expect(find.text('暂无日志'), findsOneWidget);
    expect(controller.entries, isEmpty);
  });

  testWidgets('shows crash diagnostics filter and status guidance', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = AppLogController.memory();
    controller.warning(
      category: AppLogCategory.crashDiagnostics,
      title: '检测到上次疑似异常退出',
      message: '上次会话没有记录到正常结束。',
    );
    controller.error(
      category: AppLogCategory.crashDiagnostics,
      title: '捕获未处理 Dart 异常',
      message: 'Bad state: boom',
      details: 'source=zone',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildPetNoteTheme(Brightness.light),
        home: LogCenterPage(controller: controller),
      ),
    );

    expect(find.text('异常退出'), findsWidgets);
    expect(find.text('异常退出线索'), findsOneWidget);
    expect(find.text('最近检测到疑似异常退出'), findsOneWidget);
    expect(find.text('系统闪退日志查看指引'), findsOneWidget);

    await tester.tap(find.text('异常退出').first);
    await tester.pumpAndSettle();

    expect(find.text('捕获未处理 Dart 异常'), findsOneWidget);
    expect(find.text('检测到上次疑似异常退出'), findsOneWidget);
  });
}
