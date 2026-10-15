import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/program.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import 'program_detail_page.dart';

/// صفحة قائمة البرامج: عرضها، وإنشاء برنامج جديد، وتعديله، وحذفه.
class ProgramsPage extends StatefulWidget {
  const ProgramsPage({Key? key}) : super(key: key);

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  final StorageService _storage = StorageService.instance;

  void _openProgram(String programId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => ProgramDetailPage(programId: programId),
      ),
    );
  }

  Future<void> _createProgram() async {
    final Program? created = await showProgramEditor(context);
    if (created == null) return;
    await _storage.addProgram(created);
    if (!mounted) return;
    // نفتح البرنامج الجديد مباشرة ليضيف المستخدم تمارينه.
    _openProgram(created.id);
  }

  Future<void> _editProgram(Program program) async {
    final Program? edited = await showProgramEditor(context, existing: program);
    if (edited == null) return;
    await _storage.updateProgram(edited);
  }

  Future<void> _deleteProgram(Program program) async {
    final bool ok = await showConfirmDialog(
      context,
      title: 'حذف البرنامج',
      message:
          'سيُحذف برنامج «${program.name}» بكل تمارينه. سجل تطورك السابق يبقى محفوظاً.',
    );
    if (!ok) return;
    await _storage.deleteProgram(program.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('برامجي')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProgram,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'برنامج جديد',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: AnimatedBuilder(
        animation: _storage,
        builder: (BuildContext context, Widget? _) {
          final List<Program> programs = _storage.programs;
          if (programs.isEmpty) {
            return EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'لا توجد برامج بعد',
              message:
                  'أنشئ برنامجاً مثل «البلانش» أو «الظهر»، ثم أضف له تمارينه وأيامه.',
              buttonLabel: 'إنشاء برنامج',
              onPressed: _createProgram,
            );
          }
          final int today = DateTime.now().weekday;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: programs.length,
            separatorBuilder: (BuildContext _, int __) =>
                const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final Program p = programs[index];
              return _ProgramCard(
                program: p,
                isToday: p.trainsOn(today),
                onTap: () => _openProgram(p.id),
                onEdit: () => _editProgram(p),
                onDelete: () => _deleteProgram(p),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    Key? key,
    required this.program,
    required this.isToday,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  final Program program;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  int get _totalSets {
    int total = 0;
    for (final Exercise e in program.exercises) {
      total += e.sets;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        program.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (isToday) ...<Widget>[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'اليوم',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  program.daysLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  program.isEmpty
                      ? 'لا توجد تمارين بعد'
                      : '${program.exerciseCount} تمارين • $_totalSets جولة',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: scheme.onSurfaceVariant),
            onSelected: (String value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (BuildContext _) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text('تعديل')),
              PopupMenuItem<String>(value: 'delete', child: Text('حذف')),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// نافذة إنشاء/تعديل برنامج (اسمه وأيام تنفيذه).
// تُستخدم من هذه الصفحة ومن صفحة تفاصيل البرنامج.
// ============================================================

Future<Program?> showProgramEditor(
  BuildContext context, {
  Program? existing,
}) {
  return showDialog<Program>(
    context: context,
    builder: (BuildContext ctx) => _ProgramEditorDialog(existing: existing),
  );
}

class _ProgramEditorDialog extends StatefulWidget {
  const _ProgramEditorDialog({Key? key, this.existing}) : super(key: key);

  final Program? existing;

  @override
  State<_ProgramEditorDialog> createState() => _ProgramEditorDialogState();
}

class _ProgramEditorDialogState extends State<_ProgramEditorDialog> {
  late final TextEditingController _nameController;
  late final Set<int> _days;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _days = Set<int>.from(widget.existing?.days ?? const <int>[]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'اكتب اسم البرنامج');
      return;
    }
    final List<int> days = _days.toList()..sort();
    final Program? existing = widget.existing;
    final Program result = existing != null
        ? existing.copyWith(name: name, days: days)
        : Program(id: Program.newId(), name: name, days: days);
    Navigator.of(context).pop<Program>(result);
  }

  @override
  Widget build(BuildContext context) {
    final bool isNew = widget.existing == null;
    return AlertDialog(
      title: Text(isNew ? 'برنامج جديد' : 'تعديل البرنامج'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _nameController,
            autofocus: isNew,
            textInputAction: TextInputAction.done,
            onChanged: (String _) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: AppTheme.inputDecoration(
              context,
              label: 'اسم البرنامج',
              hint: 'مثال: البلانش',
            ).copyWith(errorText: _error),
          ),
          const SizedBox(height: 18),
          const Text(
            'أيام التمرين',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              for (final int d in kWeekOrder)
                FilterChip(
                  label: Text(kDayNames[d] ?? ''),
                  selected: _days.contains(d),
                  selectedColor: AppColors.accent.withOpacity(0.25),
                  checkmarkColor: AppColors.accent,
                  onSelected: (bool on) {
                    setState(() {
                      if (on) {
                        _days.add(d);
                      } else {
                        _days.remove(d);
                      }
                    });
                  },
                ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isNew ? 'إنشاء' : 'حفظ'),
        ),
      ],
    );
  }
}
