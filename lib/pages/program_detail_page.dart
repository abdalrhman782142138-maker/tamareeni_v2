import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/program.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'exercise_form_page.dart';
import 'exercise_detail_page.dart';
import 'programs_page.dart';
import 'workout_page.dart';

/// صفحة برنامج واحد: تمارينه (إضافة، وتعديل، وحذف، وترتيب بالسحب)
/// وزر بدء التمرين.
class ProgramDetailPage extends StatefulWidget {
  const ProgramDetailPage({Key? key, required this.programId})
      : super(key: key);

  final String programId;

  @override
  State<ProgramDetailPage> createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage> {
  final StorageService _storage = StorageService.instance;

  Future<void> _editProgram(Program program) async {
    final Program? edited = await showProgramEditor(context, existing: program);
    if (edited == null) return;
    await _storage.updateProgram(edited);
  }

  Future<void> _addExercise() async {
    final Exercise? created = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute<Exercise>(
        builder: (BuildContext _) => const ExerciseFormPage(),
      ),
    );
    if (created == null) return;
    final Program? current = _storage.programById(widget.programId);
    if (current == null) return;
    await _storage.updateProgram(current.withExerciseAdded(created));
  }

  Future<void> _editExercise(Exercise exercise) async {
    final Exercise? edited = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute<Exercise>(
        builder: (BuildContext _) => ExerciseFormPage(exercise: exercise),
      ),
    );
    if (edited == null) return;
    final Program? current = _storage.programById(widget.programId);
    if (current == null) return;
    await _storage.updateProgram(current.withExerciseUpdated(edited));
  }

  Future<void> _duplicateExercise(Exercise exercise) async {
    final Program? current = _storage.programById(widget.programId);
    if (current == null) return;
    final Exercise copy = exercise.copyWith(id: Exercise.newId());
    await _storage.updateProgram(current.withExerciseAdded(copy));
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final bool ok = await showConfirmDialog(
      context,
      title: 'حذف التمرين',
      message: 'هل تريد حذف «${exercise.name}» من هذا البرنامج؟',
    );
    if (!ok) return;
    final Program? current = _storage.programById(widget.programId);
    if (current == null) return;
    await _storage.updateProgram(current.withExerciseRemoved(exercise.id));
  }

  Future<void> _reorder(Program program, int oldIndex, int newIndex) async {
    await _storage.updateProgram(
      program.withExercisesReordered(oldIndex, newIndex),
    );
  }

  void _showExerciseDetails(Exercise exercise) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => ExerciseDetailPage(exercise: exercise),
      ),
    );
  }

  void _startWorkout({String? onlyExerciseId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => WorkoutPage(
          programId: widget.programId,
          onlyExerciseId: onlyExerciseId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _storage,
      builder: (BuildContext context, Widget? _) {
        final Program? program = _storage.programById(widget.programId);
        if (program == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'هذا البرنامج غير موجود',
            ),
          );
        }
        return _buildScaffold(context, program);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Program program) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Exercise> exercises = program.exercises;

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            tooltip: 'تعديل البرنامج',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editProgram(program),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SoftCard(
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          program.daysLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${program.exerciseCount} تمارين',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: exercises.isEmpty
                ? EmptyState(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'لا توجد تمارين في هذا البرنامج',
                    message:
                        'أضف التمارين بأسمائها وعدّاتها وجولاتها ومدتها، ثم ابدأ التمرين.',
                    buttonLabel: 'إضافة تمرين',
                    onPressed: _addExercise,
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    buildDefaultDragHandles: false,
                    itemCount: exercises.length,
                    onReorder: (int oldIndex, int newIndex) =>
                        _reorder(program, oldIndex, newIndex),
                    itemBuilder: (BuildContext context, int index) {
                      final Exercise e = exercises[index];
                      return _ExerciseTile(
                        key: ValueKey<String>(e.id),
                        index: index,
                        exercise: e,
                        onEdit: () => _editExercise(e),
                        onDetails: () => _showExerciseDetails(e),
                        onRun: () => _startWorkout(onlyExerciseId: e.id),
                        onDuplicate: () => _duplicateExercise(e),
                        onDelete: () => _deleteExercise(e),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة تمرين'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: program.isEmpty ? null : () => _startWorkout(),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('ابدأ التمرين'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    Key? key,
    required this.index,
    required this.exercise,
    required this.onEdit,
    required this.onDetails,
    required this.onRun,
    required this.onDuplicate,
    required this.onDelete,
  }) : super(key: key);

  final int index;
  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDetails;
  final VoidCallback onRun;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        onTap: onDetails,
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
        child: Row(
          children: <Widget>[
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    exercise.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.summary,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.restLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (exercise.note.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      exercise.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
              tooltip: 'تشغيل هذا التمرين فقط',
              icon: const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.accent,
                size: 30,
              ),
              onPressed: onRun,
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: scheme.onSurfaceVariant,
              ),
              onSelected: (String value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'details') {
                  onDetails();
                } else if (value == 'duplicate') {
                  onDuplicate();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext _) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'details', child: Text('تفاصيل العضلات')),
                PopupMenuItem<String>(value: 'edit', child: Text('تعديل')),
                PopupMenuItem<String>(
                  value: 'duplicate',
                  child: Text('تكرار'),
                ),
                PopupMenuItem<String>(value: 'delete', child: Text('حذف')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
