import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../widgets/body_muscle_map.dart';

class ExerciseDetailPage extends StatefulWidget {
  const ExerciseDetailPage({Key? key, required this.exercise}) : super(key: key);
  final Exercise exercise;

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  bool _isFront = true;

  @override
  Widget build(BuildContext context) {
    final Exercise exercise = widget.exercise;
    final String description = exercise.effectiveDescription;
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.displayNameArabic),
        actions: <Widget>[
          IconButton(
            tooltip: 'تبديل المنظر الأمامي والخلفي',
            icon: const Icon(Icons.flip_camera_android_rounded),
            onPressed: () => setState(() => _isFront = !_isFront),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          SizedBox(
            height: 330,
            child: BodyMuscleMap(
              activeMuscles: exercise.targetedMuscles,
              secondaryMuscles: exercise.secondaryMuscles,
              isFrontView: _isFront,
            ),
          ),
          const SizedBox(height: 18),
          Text(exercise.displayNameArabic,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          if (exercise.nameEnglish.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(exercise.nameEnglish, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Chip(label: Text('الفئة: ${exercise.category}')),
          ),
          if (exercise.targetedMuscles.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            const Text('العضلات الرئيسية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: exercise.targetedMuscles.map((String m) => Chip(
              backgroundColor: Colors.red.withOpacity(0.12), label: Text(m),
            )).toList()),
          ],
          if (exercise.secondaryMuscles.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            const Text('العضلات الثانوية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: exercise.secondaryMuscles.map((String m) => Chip(label: Text(m))).toList()),
          ],
          const SizedBox(height: 12),
          const Text('تفاصيل التمرين', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(description.isEmpty ? 'لا يوجد وصف إضافي لهذا التمرين.' : description,
              style: const TextStyle(fontSize: 16, height: 1.5)),
          const SizedBox(height: 12),
          Text(exercise.summary, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(exercise.restLabel),
        ],
      ),
    );
  }
}
