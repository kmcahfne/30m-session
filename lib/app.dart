import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoopworkApp extends StatelessWidget {
  const LoopworkApp({
    super.key,
    this.sessionDuration = const Duration(minutes: 30),
    this.onSessionCompleteFeedbackStart,
    this.onSessionCompleteFeedbackStop,
  });

  final Duration sessionDuration;
  final Future<void> Function()? onSessionCompleteFeedbackStart;
  final Future<void> Function()? onSessionCompleteFeedbackStop;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Slotty',
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        scaffoldBackgroundColor: Color(0xFFF2F2F7),
      ),
      home: TaskListPage(
        sessionDuration: sessionDuration,
        onSessionCompleteFeedbackStart: onSessionCompleteFeedbackStart,
        onSessionCompleteFeedbackStop: onSessionCompleteFeedbackStop,
      ),
    );
  }
}

class TaskListPage extends StatefulWidget {
  const TaskListPage({
    super.key,
    this.sessionDuration = const Duration(minutes: 30),
    this.onSessionCompleteFeedbackStart,
    this.onSessionCompleteFeedbackStop,
  });

  final Duration sessionDuration;
  final Future<void> Function()? onSessionCompleteFeedbackStart;
  final Future<void> Function()? onSessionCompleteFeedbackStop;

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  static const String _kTasksStorageKey = 'loopwork_tasks_v1';
  static const String _kSessionMinutesKey = 'loopwork_session_minutes_v1';
  static const String _kSessionSecondsKey = 'loopwork_session_seconds_v1';

  static const List<_TaskColorPattern> _availablePatterns = [
    _TaskColorPattern.mikan,
    _TaskColorPattern.peacock,
    _TaskColorPattern.cobalt,
    _TaskColorPattern.basil,
    _TaskColorPattern.lemon,
  ];

  final List<_PreviewTask> _tasks = [
    _PreviewTask(
      name: '請求処理',
      isSet: true,
      colorPattern: _TaskColorPattern.mikan,
    ),
    _PreviewTask(
      name: '見積もり更新',
      isSet: true,
      colorPattern: _TaskColorPattern.peacock,
    ),
    _PreviewTask(
      name: '週次レポート',
      isSet: false,
      colorPattern: _TaskColorPattern.cobalt,
    ),
    _PreviewTask(
      name: '顧客フォロー',
      isSet: false,
      colorPattern: _TaskColorPattern.basil,
    ),
    _PreviewTask(
      name: '資料整理',
      isSet: false,
      colorPattern: _TaskColorPattern.lemon,
    ),
  ];
  bool _isDeleteMode = false;
  bool _isEditingTime = false;
  _SessionStatus _sessionStatus = _SessionStatus.idle;
  List<_PreviewTask> _sessionTasks = const [];
  Timer? _countdownTimer;
  late final AudioPlayer _audioPlayer;
  late _EditableSessionTime _configuredTime;
  late _EditableSessionTime _remainingTime;
  late TextEditingController _minuteController;
  late TextEditingController _secondController;

  @override
  void initState() {
    super.initState();
    _configuredTime = _EditableSessionTime.fromDuration(widget.sessionDuration);
    _remainingTime = _configuredTime;
    _minuteController = TextEditingController(text: _configuredTime.minuteText);
    _secondController = TextEditingController(text: _configuredTime.secondText);
    _audioPlayer = AudioPlayer();
    unawaited(_loadPersistedState());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    unawaited(_audioPlayer.dispose());
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_kTasksStorageKey);
    final savedMinutes = prefs.getInt(_kSessionMinutesKey);
    final savedSeconds = prefs.getInt(_kSessionSecondsKey);

    if (!mounted) {
      return;
    }

    setState(() {
      if (tasksJson != null) {
        try {
          final decoded = jsonDecode(tasksJson) as List<dynamic>;
          _tasks
            ..clear()
            ..addAll(
              decoded.map((item) {
                final map = item as Map<String, dynamic>;
                final colorName = map['color'] as String?;
                final pattern = _availablePatterns.firstWhere(
                  (p) => p.name == colorName,
                  orElse: () => _TaskColorPattern.mikan,
                );
                return _PreviewTask(
                  name: map['name'] as String? ?? '',
                  isSet: map['isSet'] as bool? ?? false,
                  colorPattern: pattern,
                );
              }),
            );
        } catch (_) {
          // If parse fails, preserve existing defaults
        }
      }

      if (savedMinutes != null && savedSeconds != null) {
        final savedTime = _EditableSessionTime(
          minutes: savedMinutes.clamp(0, 99),
          seconds: savedSeconds.clamp(0, 99),
        );
        _configuredTime = savedTime;
        if (!_isSessionActive) {
          _remainingTime = savedTime;
          _minuteController.text = savedTime.minuteText;
          _secondController.text = savedTime.secondText;
        }
      }
    });
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _tasks
          .map(
            (task) => {
              'name': task.name,
              'isSet': task.isSet,
              'color': task.colorPattern.name,
            },
          )
          .toList();
      await prefs.setString(_kTasksStorageKey, jsonEncode(data));
    } catch (_) {
      // Storage error gracefully ignored
    }
  }

  Future<void> _saveConfiguredTime(_EditableSessionTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kSessionMinutesKey, time.minutes);
      await prefs.setInt(_kSessionSecondsKey, time.seconds);
    } catch (_) {
      // Storage error gracefully ignored
    }
  }

  @override
  Widget build(BuildContext context) {
    final workDurationLabel = _remainingTime.label;
    final setTasks = _tasks.where((task) => task.isSet).toList(growable: false);
    final unsetTasks = _tasks
        .where((task) => !task.isSet)
        .toList(growable: false);
    final orderedTasks = [...setTasks, ...unsetTasks];

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF2F2F7),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showAddTaskDialog,
          child: const Icon(CupertinoIcons.add, size: 30),
        ),
        middle: const SizedBox.shrink(),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _toggleDeleteMode,
          child: Icon(
            _isDeleteMode ? CupertinoIcons.trash_fill : CupertinoIcons.trash,
            size: 28,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 164,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isEditingTime)
                        _TimeEditor(
                          minuteController: _minuteController,
                          secondController: _secondController,
                        )
                      else
                        Text(
                          workDurationLabel,
                          key: const ValueKey('session-timer-label'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            color: CupertinoColors.black,
                          ),
                        ),
                      Positioned(
                        right: 0,
                        child: CupertinoButton(
                          key: const ValueKey('edit-session-time-button'),
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 28),
                          onPressed: _isSessionActive
                              ? null
                              : _toggleTimeEditMode,
                          child: Icon(
                            CupertinoIcons.pencil,
                            size: 20,
                            color: _isSessionActive
                                ? CupertinoColors.inactiveGray
                                : _isEditingTime
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                itemBuilder: (context, index) {
                  final task = orderedTasks[index];
                  return _TaskBar(
                    task: task,
                    isDeleteMode: _isDeleteMode && !_isSessionActive,
                    isInActiveSession: _sessionTasks.contains(task),
                    onTap: () => _toggleTask(task),
                    onDelete: () => _deleteTask(task),
                  );
                },
                separatorBuilder: (_, index) => const SizedBox(height: 7),
                itemCount: orderedTasks.length,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
              child: SizedBox(
                width: double.infinity,
                child: SizedBox(
                  height: 46,
                  child: _buildSessionActionBar(setTasks),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTask(_PreviewTask target) {
    if (_isSessionActive) {
      return;
    }

    setState(() {
      target.isSet = !target.isSet;
    });
    unawaited(_saveTasks());
  }

  Future<void> _showAddTaskDialog() async {
    final controller = TextEditingController();
    var selectedPattern = _TaskColorPattern.cobalt;
    final taskDraft = await showCupertinoDialog<_NewTaskDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return CupertinoAlertDialog(
              title: const Text('タスクを追加'),
              content: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    CupertinoTextField(
                      key: const ValueKey('add-task-text-field'),
                      controller: controller,
                      autofocus: true,
                      placeholder: 'タスク名',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        Navigator.of(dialogContext).pop(
                          _NewTaskDraft(
                            name: value,
                            colorPattern: selectedPattern,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _TaskColorPicker(
                      selectedPattern: selectedPattern,
                      patterns: _availablePatterns,
                      onSelected: (pattern) {
                        setDialogState(() {
                          selectedPattern = pattern;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                CupertinoDialogAction(
                  key: const ValueKey('confirm-add-task'),
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      _NewTaskDraft(
                        name: controller.text,
                        colorPattern: selectedPattern,
                      ),
                    );
                  },
                  child: const Text('追加'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (!mounted) {
      return;
    }

    final normalized = taskDraft?.name.trim() ?? '';
    if (normalized.isEmpty) {
      return;
    }

    setState(() {
      _tasks.add(
        _PreviewTask(
          name: normalized,
          isSet: false,
          colorPattern: taskDraft!.colorPattern,
        ),
      );
    });
    unawaited(_saveTasks());
  }

  void _deleteTask(_PreviewTask target) {
    if (_isSessionActive) {
      return;
    }

    setState(() {
      _tasks.remove(target);
    });
    unawaited(_saveTasks());
  }

  void _toggleDeleteMode() {
    if (_isSessionActive) {
      return;
    }

    setState(() {
      _isDeleteMode = !_isDeleteMode;
    });
  }

  void _toggleTimeEditMode() {
    if (_isSessionActive) {
      return;
    }

    if (_isEditingTime) {
      _applyEditedTime();
      return;
    }

    setState(() {
      _isEditingTime = true;
      _minuteController.text = _configuredTime.minuteText;
      _secondController.text = _configuredTime.secondText;
    });
  }

  Widget _buildSessionActionBar(List<_PreviewTask> setTasks) {
    if (_sessionStatus == _SessionStatus.idle) {
      return CupertinoButton(
        key: const ValueKey('start-session-button'),
        color: const Color(0xFF1A73E8),
        borderRadius: BorderRadius.circular(14),
        onPressed: setTasks.isEmpty || _isEditingTime ? null : _startSession,
        padding: EdgeInsets.zero,
        child: const Text(
          '開始',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
      );
    }

    final primaryLabel = _sessionStatus == _SessionStatus.running ? '停止' : '再開';
    final primaryAction = _sessionStatus == _SessionStatus.running
        ? _pauseSession
        : _resumeSession;

    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            key: const ValueKey('pause-resume-session-button'),
            color: const Color(0xFF8E8E93),
            borderRadius: BorderRadius.circular(14),
            onPressed: primaryAction,
            padding: EdgeInsets.zero,
            child: Text(
              primaryLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CupertinoButton(
            key: const ValueKey('clear-session-button'),
            color: const Color(0xFF1A73E8),
            borderRadius: BorderRadius.circular(14),
            onPressed: _clearSession,
            padding: EdgeInsets.zero,
            child: const Text(
              'クリア',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startSession() {
    if (_isEditingTime) {
      return;
    }

    final selectedTasks = _tasks
        .where((task) => task.isSet)
        .toList(growable: false);
    if (selectedTasks.isEmpty) {
      return;
    }

    _countdownTimer?.cancel();
    setState(() {
      _sessionTasks = selectedTasks;
      _sessionStatus = _SessionStatus.running;
      _remainingTime = _configuredTime;
      _isDeleteMode = false;
      _isEditingTime = false;
    });
    _startCountdown();
  }

  void _pauseSession() {
    _countdownTimer?.cancel();
    setState(() {
      _sessionStatus = _SessionStatus.paused;
    });
  }

  void _resumeSession() {
    setState(() {
      _sessionStatus = _SessionStatus.running;
    });
    _startCountdown();
  }

  void _clearSession() {
    _countdownTimer?.cancel();
    setState(() {
      _sessionStatus = _SessionStatus.idle;
      _sessionTasks = const [];
      _remainingTime = _configuredTime;
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _sessionStatus != _SessionStatus.running) {
        timer.cancel();
        return;
      }

      if (_remainingTime.isZero) {
        timer.cancel();
        _completeSession();
        return;
      }

      setState(() {
        _remainingTime = _remainingTime.decrement();
      });

      if (_remainingTime.isZero) {
        timer.cancel();
        _completeSession();
      }
    });
  }

  Future<void> _completeSession() async {
    final completedTasks = List<_PreviewTask>.from(_sessionTasks);

    setState(() {
      for (final task in completedTasks) {
        task.isSet = false;
      }
      _sessionStatus = _SessionStatus.idle;
      _sessionTasks = const [];
      _remainingTime = _configuredTime;
    });

    unawaited(_saveTasks());
    unawaited(_startCompletionFeedback());

    if (!mounted) {
      return;
    }

    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('セッション終了'),
          content: const Text('作業時間が終了しました。'),
          actions: [
            CupertinoDialogAction(
              onPressed: () async {
                await _stopCompletionFeedback();
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  bool get _isSessionActive => _sessionStatus != _SessionStatus.idle;

  Future<void> _startCompletionFeedback() async {
    if (widget.onSessionCompleteFeedbackStart case final callback?) {
      await callback();
      return;
    }

    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('audio/session_end_alarm.mp3'));
    await HapticFeedback.mediumImpact();
  }

  Future<void> _stopCompletionFeedback() async {
    if (widget.onSessionCompleteFeedbackStop case final callback?) {
      await callback();
      return;
    }

    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.release);
  }

  void _applyEditedTime() {
    final nextTime = _EditableSessionTime(
      minutes: _parseTimeSegment(_minuteController.text),
      seconds: _parseTimeSegment(_secondController.text),
    );

    setState(() {
      _configuredTime = nextTime;
      _remainingTime = nextTime;
      _isEditingTime = false;
      _minuteController.text = nextTime.minuteText;
      _secondController.text = nextTime.secondText;
    });
    unawaited(_saveConfiguredTime(nextTime));
  }

  int _parseTimeSegment(String value) {
    final parsed = int.tryParse(value) ?? 0;
    return parsed.clamp(0, 99);
  }
}

class _TaskColorPicker extends StatelessWidget {
  const _TaskColorPicker({
    required this.selectedPattern,
    required this.patterns,
    required this.onSelected,
  });

  final _TaskColorPattern selectedPattern;
  final List<_TaskColorPattern> patterns;
  final ValueChanged<_TaskColorPattern> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final pattern in patterns)
          GestureDetector(
            key: ValueKey('color-option-${pattern.name}'),
            onTap: () => onSelected(pattern),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: pattern.backgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedPattern == pattern
                      ? CupertinoColors.black
                      : CupertinoColors.white,
                  width: selectedPattern == pattern ? 2 : 1,
                ),
              ),
              child: selectedPattern == pattern
                  ? Icon(
                      CupertinoIcons.check_mark,
                      size: 16,
                      color: pattern.foregroundColor,
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

class _TimeEditor extends StatelessWidget {
  const _TimeEditor({
    required this.minuteController,
    required this.secondController,
  });

  final TextEditingController minuteController;
  final TextEditingController secondController;

  @override
  Widget build(BuildContext context) {
    const inputStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: CupertinoColors.black,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const ValueKey('session-minute-box'),
          width: 44,
          height: 36,
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: CupertinoTextField(
            key: const ValueKey('session-minute-field'),
            controller: minuteController,
            padding: EdgeInsets.zero,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            style: inputStyle,
            decoration: null,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(':', style: inputStyle),
        ),
        Container(
          key: const ValueKey('session-second-box'),
          width: 44,
          height: 36,
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: CupertinoTextField(
            key: const ValueKey('session-second-field'),
            controller: secondController,
            padding: EdgeInsets.zero,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            style: inputStyle,
            decoration: null,
          ),
        ),
      ],
    );
  }
}

class _TaskBar extends StatelessWidget {
  const _TaskBar({
    required this.task,
    required this.isDeleteMode,
    required this.isInActiveSession,
    required this.onTap,
    required this.onDelete,
  });

  final _PreviewTask task;
  final bool isDeleteMode;
  final bool isInActiveSession;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final pattern = task.colorPattern;
    final labelColor = pattern.foregroundColor;
    const barRadius = 14.0;
    const revealWidth = 48.0;

    return GestureDetector(
      key: ValueKey('task-${task.name}-${task.isSet ? 'set' : 'unset'}'),
      onTap: onTap,
      child: SizedBox(
        height: 46,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final frontLeft = task.isSet ? revealWidth : 0.0;
            final frontWidth = constraints.maxWidth - frontLeft;

            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(barRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          isInActiveSession
                              ? CupertinoIcons.play_fill
                              : CupertinoIcons.clock,
                          size: 17,
                          color: pattern.iconColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: frontLeft,
                  top: 0,
                  width: frontWidth,
                  bottom: 0,
                  child: DecoratedBox(
                    key: ValueKey('task-surface-${task.name}-${pattern.name}'),
                    decoration: BoxDecoration(
                      color: pattern.backgroundColor,
                      borderRadius: BorderRadius.circular(barRadius),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: task.isSet ? 18 : 14,
                        right: isDeleteMode ? 6 : 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.name,
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isDeleteMode)
                            CupertinoButton(
                              key: ValueKey('delete-task-${task.name}'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              minimumSize: const Size(30, 30),
                              onPressed: onDelete,
                              child: Icon(
                                CupertinoIcons.delete,
                                size: 18,
                                color: labelColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NewTaskDraft {
  const _NewTaskDraft({required this.name, required this.colorPattern});

  final String name;
  final _TaskColorPattern colorPattern;
}

class _PreviewTask {
  _PreviewTask({
    required this.name,
    required this.isSet,
    required this.colorPattern,
  });

  final String name;
  bool isSet;
  final _TaskColorPattern colorPattern;
}

class _TaskColorPattern {
  const _TaskColorPattern._({
    required this.name,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconColor,
  });

  final String name;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconColor;

  static const mikan = _TaskColorPattern._(
    name: 'mikan',
    backgroundColor: Color(0xFFF4511E),
    foregroundColor: CupertinoColors.white,
    iconColor: Color(0xFFF4511E),
  );

  static const lemon = _TaskColorPattern._(
    name: 'lemon',
    backgroundColor: Color(0xFFF6BF26),
    foregroundColor: Color(0xFF3C4043),
    iconColor: Color(0xFFF6BF26),
  );

  static const basil = _TaskColorPattern._(
    name: 'basil',
    backgroundColor: Color(0xFF0B8043),
    foregroundColor: CupertinoColors.white,
    iconColor: Color(0xFF0B8043),
  );

  static const peacock = _TaskColorPattern._(
    name: 'peacock',
    backgroundColor: Color(0xFF039BE5),
    foregroundColor: CupertinoColors.white,
    iconColor: Color(0xFF039BE5),
  );

  static const cobalt = _TaskColorPattern._(
    name: 'cobalt',
    backgroundColor: Color(0xFF4285F4),
    foregroundColor: CupertinoColors.white,
    iconColor: Color(0xFF4285F4),
  );
}

class _EditableSessionTime {
  const _EditableSessionTime({required this.minutes, required this.seconds});

  factory _EditableSessionTime.fromDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    return _EditableSessionTime(
      minutes: (totalSeconds ~/ 60).clamp(0, 99),
      seconds: (totalSeconds % 60).clamp(0, 99),
    );
  }

  final int minutes;
  final int seconds;

  String get minuteText => minutes.toString().padLeft(2, '0');
  String get secondText => seconds.toString().padLeft(2, '0');
  String get label => '$minuteText:$secondText';
  bool get isZero => minutes == 0 && seconds == 0;

  _EditableSessionTime decrement() {
    if (isZero) {
      return this;
    }

    if (seconds > 0) {
      return _EditableSessionTime(minutes: minutes, seconds: seconds - 1);
    }

    if (minutes > 0) {
      return _EditableSessionTime(minutes: minutes - 1, seconds: 99);
    }

    return const _EditableSessionTime(minutes: 0, seconds: 0);
  }
}

enum _SessionStatus { idle, running, paused }
