import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/session_log.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/progress_chart.dart';

/// جدول التطور: اختر تمريناً لترى رسمه البياني وأفضل رقم وسجل جلساته.
class ProgressPage extends StatefulWidget {
  const ProgressPage({Key? key}) : super(key: key);

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final StorageService _storage = StorageService.instance;
  String? _selectedKey;

  static String _shortDate(DateTime d) => '${d.day}/${d.month}';

  static String _fullDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  static String _setsText(SessionLog l) {
    final List<String> parts = <String>[];
    for (final SetResult r in l.results) {
      parts.add(l.isTimed ? '${r.seconds}ث' : '${r.reps}');
    }
    if (parts.isEmpty) return 'بدون جولات';
    return parts.join(' • ');
  }

  Future<void> _deleteLog(SessionLog log) async {
    final bool ok = await showConfirmDialog(
      context,
      title: 'حذف الجلسة',
      message: 'هل تريد حذف هذه الجلسة من سجل التطور؟',
    );
    if (!ok) return;
    await _storage.deleteLog(log.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تطوري')),
      body: AnimatedBuilder(
        animation: _storage,
        builder: (BuildContext context, Widget? _) {
          final List<String> keys = _storage.loggedExerciseKeys();
          if (keys.isEmpty) {
            return const EmptyState(
              icon: Icons.trending_up_rounded,
              title: 'لا يوجد تطور بعد',
              message:
                  'أنهِ جولة واحدة على الأقل من أي تمرين، وسيظهر هنا رسمك البياني وأفضل أرقامك.',
            );
          }
          final String selected =
              (_selectedKey != null && keys.contains(_selectedKey))
                  ? _selectedKey!
                  : keys.first;
          return _buildContent(context, keys, selected);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<String> keys,
    String selected,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<SessionLog> logs = _storage.logsForExercise(selected);
    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }
    final bool timed = logs.last.isTimed;

    // أفضل قيمة لكل يوم، بالترتيب الزمني.
    final List<String> dayOrder = <String>[];
    final Map<String, int> bestByDay = <String, int>{};
    final Map<String, DateTime> dateByDay = <String, DateTime>{};
    for (final SessionLog l in logs) {
      final String dk = l.dayKey;
      final int v = l.metricValue;
      final int? existing = bestByDay[dk];
      if (existing == null) {
        bestByDay[dk] = v;
        dateByDay[dk] = l.date;
        dayOrder.add(dk);
      } else if (v > existing) {
        bestByDay[dk] = v;
      }
    }

    final int startIndex = math.max(0, dayOrder.length - 20);
    final List<String> shownDays = dayOrder.sublist(startIndex);
    final List<double> values = <double>[];
    final List<String> labels = <String>[];
    for (final String dk in shownDays) {
      values.add((bestByDay[dk] ?? 0).toDouble());
      labels.add(_shortDate(dateByDay[dk] ?? DateTime.now()));
    }

    int bestEver = 0;
    for (final int v in bestByDay.values) {
      if (v > bestEver) bestEver = v;
    }
    final int firstValue = bestByDay[dayOrder.first] ?? 0;
    final int lastValue = bestByDay[dayOrder.last] ?? 0;
    final int diff = lastValue - firstValue;

    String fmt(int v) => timed ? formatDurationText(v) : '$v';
    String diffText;
    if (dayOrder.length < 2) {
      diffText = '—';
    } else if (diff > 0) {
      diffText = '+${fmt(diff)}';
    } else if (diff < 0) {
      diffText = '-${fmt(-diff)}';
    } else {
      diffText = '0';
    }

    final List<SessionLog> recent = logs.reversed.take(15).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        // --- اختيار التمرين ---
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: keys.length,
            separatorBuilder: (BuildContext _, int __) =>
                const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              final String key = keys[index];
              final bool isSelected = key == selected;
              return ChoiceChip(
                label: Text(key),
                selected: isSelected,
                selectedColor: AppColors.accent,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : scheme.onSurface,
                ),
                onSelected: (bool _) => setState(() => _selectedKey = key),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // --- الرسم البياني ---
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                timed ? 'أطول ثبات (بالثواني)' : 'أفضل جولة (عدّات)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'آخر ${shownDays.length} يوم تمرين',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              ProgressChart(values: values, labels: labels),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // --- أرقامك ---
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                icon: Icons.military_tech_rounded,
                value: fmt(bestEver),
                label: 'أفضل رقم',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.flag_rounded,
                value: fmt(lastValue),
                label: 'آخر جلسة',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                icon: Icons.trending_up_rounded,
                value: diffText,
                label: 'التحسّن',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- سجل الجلسات ---
        const SectionHeader(title: 'سجل الجلسات'),
        const SizedBox(height: 10),
        for (final SessionLog l in recent)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _fullDate(l.date),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _setsText(l),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (l.programName.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            l.programName,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'حذف الجلسة',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () => _deleteLog(l),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
