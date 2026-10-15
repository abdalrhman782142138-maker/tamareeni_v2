import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exercise.dart';
import '../models/program.dart';
import '../models/session_log.dart';
import '../services/storage_service.dart';
import '../theme.dart';

enum _Phase { ready, prep, working, rest, finished }

/// شاشة التمرين الحيّة.
/// - [onlyExerciseId] null: تشغّل كل تمارين البرنامج تمريناً بعد تمرين.
/// - غير null: تشغّل هذا التمرين وحده.
///
/// كل جولة تُسجَّل في سجل التطور فور انتهائها، فلا يضيع شيء إذا خرجت مبكراً.
class WorkoutPage extends StatefulWidget {
  const WorkoutPage({
    Key? key,
    required this.programId,
    this.onlyExerciseId,
  }) : super(key: key);

  final String programId;
  final String? onlyExerciseId;

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final StorageService _storage = StorageService.instance;

  Program? _program;
  List<Exercise> _exercises = <Exercise>[];
  int _exIndex = 0;

  // حالة التمرين الحالي
  List<SetResult> _results = <SetResult>[];
  String _logId = '';
  DateTime _exerciseDate = DateTime.now();
  int _repsInput = 10;

  // الجلسة كلها
  final List<SessionLog> _doneLogs = <SessionLog>[];
  final DateTime _sessionStart = DateTime.now();
  int _totalSeconds = 0;

  // المؤقت
  _Phase _phase = _Phase.ready;
  Timer? _timer;
  DateTime _phaseStart = DateTime.now();
  DateTime _phaseEnd = DateTime.now();
  int _phaseTotal = 0;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    final Program? p = _storage.programById(widget.programId);
    _program = p;
    if (p != null) {
      final String? only = widget.onlyExerciseId;
      if (only != null) {
        _exercises = p.exercises.where((Exercise e) => e.id == only).toList();
      } else {
        _exercises = List<Exercise>.from(p.exercises);
      }
    }
    if (_exercises.isNotEmpty) _resetExercise();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------
  // مساعدات الحالة
  // ------------------------------------------------------------

  Exercise get _current => _exercises[_exIndex];

  int get _targetSets => math.max(1, _current.sets);

  bool get _isLastExercise => _exIndex + 1 >= _exercises.length;

  /// يهيّئ حالة التمرين الحالي (بدون setState، يُستدعى داخلها أو قبل البناء).
  void _resetExercise() {
    _results = <SetResult>[];
    _logId = SessionLog.newId();
    _exerciseDate = DateTime.now();
    _repsInput = _current.reps > 0 ? _current.reps : 10;
  }

  SessionLog _buildLog() {
    return SessionLog(
      id: _logId,
      date: _exerciseDate,
      exerciseName: _current.name,
      programId: _program?.id ?? '',
      programName: _program?.name ?? '',
      isTimed: _current.isTimed,
      targetSets: _targetSets,
      results: List<SetResult>.from(_results),
    );
  }

  double get _overallProgress {
    int total = 0;
    int done = 0;
    for (int i = 0; i < _exercises.length; i++) {
      final int s = math.max(1, _exercises[i].sets);
      total += s;
      if (i < _exIndex) {
        done += s;
      } else if (i == _exIndex) {
        done += math.min(_results.length, s);
      }
    }
    if (total == 0) return 0;
    return done / total;
  }

  void _signal({bool strong = false}) {
    if (_storage.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (_storage.vibrationEnabled) {
      if (strong) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  // ------------------------------------------------------------
  // المؤقت
  // ------------------------------------------------------------

  void _beginCountdown(_Phase phase, int seconds) {
    _timer?.cancel();
    final DateTime now = DateTime.now();
    setState(() {
      _phase = phase;
      _phaseStart = now;
      _phaseEnd = now.add(Duration(seconds: seconds));
      _phaseTotal = seconds;
      _remaining = seconds;
    });
    _timer = Timer.periodic(
      const Duration(milliseconds: 200),
      (Timer _) => _tick(),
    );
  }

  void _tick() {
    if (!mounted) {
      _timer?.cancel();
      return;
    }
    final int ms = _phaseEnd.difference(DateTime.now()).inMilliseconds;
    if (ms <= 0) {
      _timer?.cancel();
      _onCountdownEnd();
      return;
    }
    final int left = (ms / 1000).ceil();
    if (left != _remaining) {
      setState(() => _remaining = left);
      if (left <= 3) _signal();
    }
  }

  void _onCountdownEnd() {
    switch (_phase) {
      case _Phase.prep:
        _signal(strong: true);
        _beginCountdown(_Phase.working, _current.durationSeconds);
        break;
      case _Phase.working:
        _finishSet(seconds: _current.durationSeconds);
        break;
      case _Phase.rest:
        _signal(strong: true);
        setState(() {
          _remaining = 0;
          _phase = _Phase.ready;
        });
        break;
      case _Phase.ready:
      case _Phase.finished:
        break;
    }
  }

  // ------------------------------------------------------------
  // مجرى التمرين
  // ------------------------------------------------------------

  void _startTimedSet() {
    _beginCountdown(_Phase.prep, 3);
  }

  void _cancelPrep() {
    _timer?.cancel();
    setState(() => _phase = _Phase.ready);
  }

  void _endHoldEarly() {
    _timer?.cancel();
    int elapsed = DateTime.now().difference(_phaseStart).inSeconds;
    if (elapsed > _current.durationSeconds) elapsed = _current.durationSeconds;
    if (elapsed < 1) {
      setState(() => _phase = _Phase.ready);
      return;
    }
    _finishSet(seconds: elapsed);
  }

  void _finishRepSet() {
    _finishSet(reps: _repsInput);
  }

  void _finishSet({int reps = 0, int seconds = 0}) {
    _timer?.cancel();
    _results = <SetResult>[
      ..._results,
      SetResult(reps: reps, seconds: seconds),
    ];
    final SessionLog log = _buildLog();
    _storage.upsertLog(log);
    _signal(strong: true);

    if (_results.length >= _targetSets) {
      _completeExercise(log);
    } else if (_current.restSeconds > 0) {
      _beginCountdown(_Phase.rest, _current.restSeconds);
    } else {
      setState(() => _phase = _Phase.ready);
    }
  }

  void _completeExercise(SessionLog log) {
    _doneLogs.add(log);
    final int rest = _current.restSeconds;
    if (_isLastExercise) {
      _finishAll();
      return;
    }
    setState(() {
      _exIndex++;
      _resetExercise();
      _phase = _Phase.ready;
    });
    if (rest > 0) _beginCountdown(_Phase.rest, rest);
  }

  void _skipExercise() {
    _timer?.cancel();
    if (_results.isNotEmpty) {
      _doneLogs.add(_buildLog());
    }
    if (_isLastExercise) {
      _finishAll();
      return;
    }
    setState(() {
      _exIndex++;
      _resetExercise();
      _phase = _Phase.ready;
    });
  }

  void _finishAll() {
    _timer?.cancel();
    final int seconds = DateTime.now().difference(_sessionStart).inSeconds;
    _signal(strong: true);
    setState(() {
      _totalSeconds = seconds;
      _phase = _Phase.finished;
    });
  }

  void _skipRest() {
    _timer?.cancel();
    setState(() {
      _remaining = 0;
      _phase = _Phase.ready;
    });
  }

  void _addRestTime() {
    setState(() {
      _phaseEnd = _phaseEnd.add(const Duration(seconds: 15));
      _phaseTotal += 15;
      _remaining += 15;
    });
  }

  Future<void> _confirmExit() async {
    final bool nothingDone = _results.isEmpty && _doneLogs.isEmpty;
    if (_phase == _Phase.finished || nothingDone) {
      Navigator.of(context).pop();
      return;
    }
    final bool ok = await showConfirmDialog(
      context,
      title: 'إنهاء التمرين',
      message: 'ما أنجزته من جولات محفوظ في سجل تطورك.',
      confirmLabel: 'خروج',
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  // ------------------------------------------------------------
  // الواجهة
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.fitness_center_rounded,
          title: 'لا توجد تمارين للتشغيل',
          message: 'أضف تمارين إلى البرنامج أولاً.',
        ),
      );
    }

    final bool finished = _phase == _Phase.finished;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _confirmExit,
        ),
        title: Text(
          finished ? 'انتهى التمرين' : (_program?.name ?? 'التمرين'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: finished ? _buildFinished() : _buildActive(),
      ),
    );
  }

  Widget _buildActive() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Exercise e = _current;
    final bool canSkip = _phase == _Phase.ready || _phase == _Phase.rest;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        children: <Widget>[
          // شريط التقدم الكلي
          Row(
            children: <Widget>[
              Text(
                'التمرين ${_exIndex + 1} من ${_exercises.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _overallProgress,
              minHeight: 6,
              color: AppColors.accent,
              backgroundColor: AppTheme.surfaceHigh(context),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      e.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (e.note.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        e.note,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildSetDots(),
                    const SizedBox(height: 28),
                    _buildCenter(),
                  ],
                ),
              ),
            ),
          ),
          _buildActions(),
          if (canSkip)
            TextButton.icon(
              onPressed: _skipExercise,
              icon: const Icon(Icons.skip_next_rounded),
              label: Text(_isLastExercise ? 'إنهاء التمرين' : 'تخطي التمرين'),
            ),
        ],
      ),
    );
  }

  Widget _buildSetDots() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final int total = _targetSets;
    final int done = _results.length;
    final int shown = math.min(done + 1, total);
    final Widget label = Text(
      'الجولة $shown من $total',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: scheme.onSurfaceVariant,
      ),
    );
    if (total > 12) return label;

    return Column(
      children: <Widget>[
        label,
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: <Widget>[
            for (int i = 0; i < total; i++)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < done
                      ? AppColors.accent
                      : AppTheme.surfaceHigh(context),
                  border: Border.all(
                    color: i == done
                        ? AppColors.accent
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _ring({required double progress, required Widget center}) {
    final double value = progress.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 12,
              color: AppColors.accent,
              backgroundColor: AppTheme.surfaceHigh(context),
            ),
          ),
          center,
        ],
      ),
    );
  }

  Widget _bigText(String text, {double size = 56}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _caption(String text) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: scheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCenter() {
    final Exercise e = _current;
    final double fraction =
        _phaseTotal > 0 ? _remaining / _phaseTotal : 0.0;

    switch (_phase) {
      case _Phase.prep:
        return _ring(
          progress: fraction,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _bigText('$_remaining', size: 80),
              _caption('استعد'),
            ],
          ),
        );

      case _Phase.working:
        return _ring(
          progress: fraction,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _bigText(formatClock(_remaining)),
              _caption('ثبّت'),
            ],
          ),
        );

      case _Phase.rest:
        final bool newExercise = _results.isEmpty;
        return Column(
          children: <Widget>[
            _ring(
              progress: fraction,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _bigText(formatClock(_remaining)),
                  _caption('راحة'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _caption(
              newExercise
                  ? 'التالي: ${e.name}'
                  : 'التالي: الجولة ${_results.length + 1} من $_targetSets',
            ),
          ],
        );

      case _Phase.ready:
        if (e.isTimed) {
          return Column(
            children: <Widget>[
              _bigText(formatClock(e.durationSeconds), size: 72),
              const SizedBox(height: 4),
              _caption('مدة الجولة'),
            ],
          );
        }
        return Column(
          children: <Widget>[
            _caption('الهدف: ${e.reps} عدّات'),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _StepButton(
                  icon: Icons.remove_rounded,
                  onTap: _repsInput > 0
                      ? () => setState(() => _repsInput--)
                      : null,
                ),
                SizedBox(
                  width: 120,
                  child: Center(child: _bigText('$_repsInput', size: 72)),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  onTap: _repsInput < 999
                      ? () => setState(() => _repsInput++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            _caption('العدّات التي أنجزتها'),
          ],
        );

      case _Phase.finished:
        return const SizedBox.shrink();
    }
    // ignore: dead_code
    return const SizedBox.shrink();
  }

  Widget _buildActions() {
    final Exercise e = _current;

    switch (_phase) {
      case _Phase.ready:
        if (e.isTimed) {
          return FilledButton.icon(
            onPressed: _startTimedSet,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 58),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('ابدأ الجولة'),
          );
        }
        return FilledButton.icon(
          onPressed: _finishRepSet,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 58),
          ),
          icon: const Icon(Icons.check_rounded),
          label: const Text('تمت الجولة'),
        );

      case _Phase.prep:
        return OutlinedButton(
          onPressed: _cancelPrep,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text('إلغاء'),
        );

      case _Phase.working:
        return FilledButton.icon(
          onPressed: _endHoldEarly,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 58),
          ),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('إنهاء الجولة'),
        );

      case _Phase.rest:
        return Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: _addRestTime,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('+15 ث'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _skipRest,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 58),
                ),
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('تخطي الراحة'),
              ),
            ),
          ],
        );

      case _Phase.finished:
        return const SizedBox.shrink();
    }
    // ignore: dead_code
    return const SizedBox.shrink();
  }

  Widget _buildFinished() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    int totalSets = 0;
    for (final SessionLog l in _doneLogs) {
      totalSets += l.setsDone;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: <Widget>[
        const SizedBox(height: 12),
        const Icon(
          Icons.emoji_events_rounded,
          size: 72,
          color: AppColors.accent,
        ),
        const SizedBox(height: 12),
        const Text(
          'أحسنت!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'تم حفظ نتائجك في جدول التطور',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                icon: Icons.timer_outlined,
                value: formatDurationText(_totalSeconds),
                label: 'الوقت الكلي',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.fitness_center_rounded,
                value: '${_doneLogs.length}',
                label: 'تمارين',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.repeat_rounded,
                value: '$totalSets',
                label: 'جولات',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_doneLogs.isEmpty)
          Text(
            'لم تُسجَّل أي جولة في هذه المرة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          )
        else
          for (final SessionLog l in _doneLogs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l.exerciseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _logSummary(l),
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  String _logSummary(SessionLog l) {
    final String sets = '${l.setsDone} من ${l.targetSets} جولات';
    if (l.isTimed) {
      return '$sets • أطول ثبات ${formatDurationText(l.bestSeconds)}';
    }
    return '$sets • أفضل جولة ${l.bestReps} عدّات';
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({Key? key, required this.icon, required this.onTap})
      : super(key: key);

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = onTap != null;
    return Material(
      color: AppTheme.surfaceHigh(context),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Icon(
            icon,
            size: 30,
            color: enabled
                ? scheme.onSurface
                : scheme.onSurfaceVariant.withOpacity(0.35),
          ),
        ),
      ),
    );
  }
}
