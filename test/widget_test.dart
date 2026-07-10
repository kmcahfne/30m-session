import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loopwork/app.dart';

void main() {
  testWidgets('renders the task list shell', (WidgetTester tester) async {
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    expect(find.text('30:00'), findsOneWidget);
    expect(find.byKey(const ValueKey('session-timer-label')), findsOneWidget);
    expect(find.text('未セット'), findsNothing);
    expect(find.text('開始'), findsOneWidget);
    expect(find.text('請求処理'), findsOneWidget);
    expect(find.text('顧客フォロー'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-請求処理-set')), findsOneWidget);
    expect(find.byKey(const ValueKey('task-週次レポート-unset')), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.pencil), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.trash_fill), findsNothing);
  });

  testWidgets('tap toggles task set state', (WidgetTester tester) async {
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('task-週次レポート-unset')), findsOneWidget);

    await tester.tap(find.text('週次レポート'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('task-週次レポート-set')), findsOneWidget);
  });

  testWidgets('add task appends an unset task to the list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('add-task-text-field')),
      '新しいタスク',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-add-task')));
    await tester.pumpAndSettle();

    expect(find.text('新しいタスク'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-新しいタスク-unset')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('task-surface-新しいタスク-cobalt')),
      findsOneWidget,
    );
  });

  testWidgets('selected color is applied to a newly added task', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('add-task-text-field')),
      '青いタスク',
    );
    await tester.tap(find.byKey(const ValueKey('color-option-cobalt')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-add-task')));
    await tester.pumpAndSettle();

    expect(find.text('青いタスク'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('task-surface-青いタスク-cobalt')),
      findsOneWidget,
    );
  });

  testWidgets('trash mode toggle shows and hides task delete buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('delete-task-資料整理')), findsNothing);

    await tester.tap(find.byIcon(CupertinoIcons.trash));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.trash_fill), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-task-資料整理')), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.trash_fill));
    await tester.pumpAndSettle();

    expect(find.byIcon(CupertinoIcons.trash), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-task-資料整理')), findsNothing);
  });

  testWidgets('tapping task delete button removes the task', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    expect(find.text('資料整理'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.trash));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-task-資料整理')));
    await tester.pumpAndSettle();

    expect(find.text('資料整理'), findsNothing);
    expect(find.byKey(const ValueKey('task-資料整理-unset')), findsNothing);
  });

  testWidgets('pencil button toggles time editing and applies value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-session-time-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('session-minute-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('session-second-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('session-minute-box')), findsOneWidget);
    expect(find.byKey(const ValueKey('session-second-box')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('session-minute-field')),
      '99',
    );
    await tester.enterText(
      find.byKey(const ValueKey('session-second-field')),
      '99',
    );

    await tester.tap(find.byKey(const ValueKey('edit-session-time-button')));
    await tester.pumpAndSettle();

    expect(find.text('99:99'), findsOneWidget);
    expect(find.byKey(const ValueKey('session-minute-field')), findsNothing);
  });

  testWidgets('start button begins countdown and supports pause/resume', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const LoopworkApp(sessionDuration: Duration(seconds: 3)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('start-session-button')));
    await tester.pump();

    expect(find.text('停止'), findsOneWidget);
    expect(find.text('クリア'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.play_fill), findsNWidgets(2));

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:02'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pause-resume-session-button')));
    await tester.pumpAndSettle();

    expect(find.text('再開'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:02'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pause-resume-session-button')));
    await tester.pumpAndSettle();
    expect(find.text('停止'), findsOneWidget);
  });

  testWidgets('time editing is disabled while session is active', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const LoopworkApp(sessionDuration: Duration(seconds: 3)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('start-session-button')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('edit-session-time-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('session-minute-field')), findsNothing);
    expect(find.text('00:03'), findsOneWidget);
  });

  testWidgets('session completion shows alert and unsets active tasks', (
    WidgetTester tester,
  ) async {
    var feedbackStarted = false;
    var feedbackStopped = false;

    await tester.pumpWidget(
      LoopworkApp(
        sessionDuration: const Duration(seconds: 1),
        onSessionCompleteFeedbackStart: () async {
          feedbackStarted = true;
        },
        onSessionCompleteFeedbackStop: () async {
          feedbackStopped = true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('start-session-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('セッション終了'), findsOneWidget);
    expect(find.text('作業時間が終了しました。'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-請求処理-unset')), findsOneWidget);
    expect(find.byKey(const ValueKey('task-見積もり更新-unset')), findsOneWidget);
    expect(feedbackStarted, isTrue);
    expect(feedbackStopped, isFalse);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(feedbackStopped, isTrue);
    expect(find.text('開始'), findsOneWidget);
    expect(find.text('00:01'), findsOneWidget);
  });
}
