import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/program.dart';
import '../models/session_log.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'program_detail_page.dart';
import 'workout_page.dart';

/// الصفحة الرئيسية: تمارين اليوم، وإحصائياتك، وآخر جلساتك.
///
/// [onGoToTab] للانتقال إلى تبويب آخر في الشريط السفلي
/// (1 البرامج، 2 التطور).
class HomePage extends StatelessWidget {
  const HomePage({Key? key, required this.onGoToTab}) : super(key: key);

  final ValueChanged<int> onGoToTab;

  void _openWorkout(BuildContext context, String programId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => WorkoutPage(programId: programId),
      ),
    );
  }

  void _openProgram(BuildContext context, String programId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => ProgramDetailPage(programId: programId),
      ),
    );
  }

  static String _dateLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final String key = SessionLog.dayKeyFor(date);
    if (key == SessionLog.dayKeyFor(now)) return 'اليوم';
    final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
    if (key == SessionLog.dayKeyFor(yesterday)) return 'أمس';
    return '${date.day}/${date.month}';
  }

  static String _logResult(SessionLog l) {
    final String sets = '${l.setsDone} جولات';
    if (l.isTimed) {
      return '$sets • أطول ثبات ${formatDurationText(l.bestSeconds)}';
    }
    return '$sets • أفضل جولة ${l.bestReps} عدّات';
  }

  @override
  Widget build(BuildContext context) {
    final StorageService storage = StorageService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('تماريني')),
      body: AnimatedBuilder(
        animation: storage,
        builder: (BuildContext context, Widget? _) {
          return _buildBody(context, storage);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, StorageService storage) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final DateTime now = DateTime.now();
    final String todayKey = SessionLog.dayKeyFor(now);

    final List<Program> todayPrograms = storage.programsForWeekday(now.weekday);
    final List<SessionLog> latest = storage.latestLogs(5);

    // البرامج التي تمرّنت عليها اليوم فعلاً.
    final Set<String> trainedProgramIds = <String>{};
    for (final SessionLog l in storage.logs) {
      if (l.dayKey == todayKey && l.programId.isNotEmpty) {
        trainedProgramIds.add(l.programId);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        // --- ترحيب ---
        Text(
          'اليوم ${kDayNames[now.weekday] ?? ''}',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          storage.trainedToday ? 'أحسنت، سجّلت تمرينك اليوم' : 'جاهز للتمرين؟',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // --- إحصائيات ---
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                icon: Icons.local_fire_department_rounded,
                value: '${storage.currentStreak}',
                label: 'أيام متتالية',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.calendar_today_rounded,
                value: '${storage.trainedDaysInLast(7)} / 7',
                label: 'آخر 7 أيام',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.emoji_events_outlined,
                value: '${storage.trainedDayKeys.length}',
                label: 'إجمالي الأيام',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- تمارين اليوم ---
        const SectionHeader(title: 'تمارين اليوم'),
        const SizedBox(height: 10),
        if (todayPrograms.isEmpty)
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'لا يوجد برنامج مجدول لهذا اليوم.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => onGoToTab(1),
                  icon: const Icon(Icons.fitness_center_rounded),
                  label: const Text('عرض البرامج'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          for (final Program p in todayPrograms)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TodayProgramCard(
                program: p,
                done: trainedProgramIds.contains(p.id),
                onStart: () => _openWorkout(context, p.id),
                onDetails: () => _openProgram(context, p.id),
              ),
            ),
        const SizedBox(height: 12),

        // --- آخر الجلسات ---
        SectionHeader(
          title: 'آخر جلساتك',
          action: latest.isEmpty ? null : 'التطور',
          onAction: () => onGoToTab(2),
        ),
        const SizedBox(height: 10),
        if (latest.isEmpty)
          SoftCard(
            child: Text(
              'لم تسجّل أي جلسة بعد. ابدأ أول تمرين وسيظهر تطورك هنا.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final SessionLog l in latest)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l.exerciseName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _logResult(l),
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _dateLabel(l.date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _TodayProgramCard extends StatelessWidget {
  const _TodayProgramCard({
    Key? key,
    required this.program,
    required this.done,
    required this.onStart,
    required this.onDetails,
  }) : super(key: key);

  final Program program;
  final bool done;
  final VoidCallback onStart;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    int totalSets = 0;
    for (final Exercise e in program.exercises) {
      totalSets += e.sets;
    }

    return SoftCard(
      borderColor: done ? AppColors.success : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  program.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (done)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            program.isEmpty
                ? 'لا توجد تمارين في هذا البرنامج بعد'
                : '${program.exerciseCount} تمارين • $totalSets جولة',
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                flex: 2,
                child: program.isEmpty
                    ? FilledButton.icon(
                        onPressed: onDetails,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('أضف تمارين'),
                      )
                    : FilledButton.icon(
                        onPressed: onStart,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(done ? 'كرّر التمرين' : 'ابدأ التمرين'),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('التفاصيل'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
