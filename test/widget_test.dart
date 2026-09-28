import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopwork/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    await tester.tap(find.byIcon(CupertinoIcons.trash));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('delete-task-資料整理')));
    await tester.pumpAndSettle();

    expect(find.text('資料整理'), findsNothing);
    expect(find.text('顧客フォロー'), findsOneWidget);
  });

  testWidgets('pencil button toggles time editing and applies value', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('session-minute-field')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('edit-session-time-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('session-minute-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('session-second-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('session-minute-field')),
      '45',
    );
    await tester.enterText(
      find.byKey(const ValueKey('session-second-field')),
      '15',
    );
    await tester.tap(find.byKey(const ValueKey('edit-session-time-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('session-minute-field')), findsNothing);
    expect(find.text('45:15'), findsOneWidget);
  });

  testWidgets('start button begins countdown and supports pause/resume', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const LoopworkApp(sessionDuration: Duration(seconds: 10)),
    );
    await tester.pumpAndSettle();

    expect(find.text('開始'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('start-session-button')));
    await tester.pump();

    expect(find.text('停止'), findsOneWidget);
    expect(find.text('クリア'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:09'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pause-resume-session-button')));
    await tester.pump();
    expect(find.text('再開'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:09'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pause-resume-session-button')));
    await tester.pump();
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

  testWidgets('persists tasks and restored state on relaunch', (
    WidgetTester tester,
  ) async {
    // 1st launch: add task and toggle set
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(CupertinoIcons.add));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('add-task-text-field')),
      '永続化タスク',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-add-task')));
    await tester.pumpAndSettle();

    expect(find.text('永続化タスク'), findsOneWidget);

    // Toggle newly added task to 'set'
    await tester.tap(find.text('永続化タスク'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('task-永続化タスク-set')), findsOneWidget);

    // 2nd launch (rebuild widget tree without clearing SharedPreferences)
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    expect(find.text('永続化タスク'), findsOneWidget);
    expect(find.byKey(const ValueKey('task-永続化タスク-set')), findsOneWidget);
  });

  testWidgets('persists configured time and restored on relaunch', (
    WidgetTester tester,
  ) async {
    // 1st launch: edit time
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-session-time-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('session-minute-field')),
      '25',
    );
    await tester.enterText(
      find.byKey(const ValueKey('session-second-field')),
      '00',
    );
    await tester.tap(find.byKey(const ValueKey('edit-session-time-button')));
    await tester.pumpAndSettle();

    expect(find.text('25:00'), findsOneWidget);

    // 2nd launch
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const LoopworkApp());
    await tester.pumpAndSettle();

    expect(find.text('25:00'), findsOneWidget);
  });
}
