import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme.dart';

/// شاشة إضافة تمرين جديد أو تعديل تمرين موجود.
/// تُرجع [Exercise] عند الحفظ، أو null إذا أُغلقت بدون حفظ.
class ExerciseFormPage extends StatefulWidget {
  const ExerciseFormPage({Key? key, this.exercise}) : super(key: key);

  /// التمرين المراد تعديله، أو null لإضافة تمرين جديد.
  final Exercise? exercise;

  @override
  State<ExerciseFormPage> createState() => _ExerciseFormPageState();
}

class _ExerciseFormPageState extends State<ExerciseFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  late final TextEditingController _englishNameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _targetedMusclesController;
  late final TextEditingController _secondaryMusclesController;
  late final TextEditingController _descriptionController;

  late bool _timed;
  late int _sets;
  late int _reps;
  late int _duration;
  late int _rest;

  bool get _isEdit => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    final Exercise? e = widget.exercise;
    _nameController = TextEditingController(text: e?.name ?? '');
    _noteController = TextEditingController(text: e?.note ?? '');
    _englishNameController = TextEditingController(text: e?.nameEnglish ?? '');
    _categoryController = TextEditingController(text: e?.category ?? 'عام');
    _targetedMusclesController = TextEditingController(text: (e?.targetedMuscles ?? const <String>[]).join('، '));
    _secondaryMusclesController = TextEditingController(text: (e?.secondaryMuscles ?? const <String>[]).join('، '));
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _timed = e != null ? e.isTimed : false;
    _sets = e != null && e.sets > 0 ? e.sets : 3;
    _reps = e != null && e.reps > 0 ? e.reps : 10;
    _duration = e != null && e.durationSeconds > 0 ? e.durationSeconds : 30;
    _rest = e != null ? e.restSeconds : 60;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _englishNameController.dispose();
    _categoryController.dispose();
    _targetedMusclesController.dispose();
    _secondaryMusclesController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> _parseMuscles(String value) => value
      .split(RegExp(r'[,،]'))
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toSet()
      .toList();

  Exercise _buildExercise() {
    return Exercise(
      id: widget.exercise?.id ?? Exercise.newId(),
      name: _nameController.text.trim(),
      reps: _timed ? 0 : _reps,
      sets: _sets,
      durationSeconds: _timed ? _duration : 0,
      restSeconds: _rest,
      note: _noteController.text.trim(),
      nameArabic: _nameController.text.trim(),
      nameEnglish: _englishNameController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? 'عام' : _categoryController.text.trim(),
      targetedMuscles: _parseMuscles(_targetedMusclesController.text),
      secondaryMuscles: _parseMuscles(_secondaryMusclesController.text),
      description: _descriptionController.text.trim(),
      imagePath: widget.exercise?.imagePath ?? '',
    );
  }

  void _save() {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop<Exercise>(_buildExercise());
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Exercise preview = _buildExercise();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل التمرين' : 'تمرين جديد'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              decoration: AppTheme.inputDecoration(
                context,
                label: 'اسم التمرين',
                hint: 'مثال: Planche Lean',
                prefixIcon: Icons.fitness_center_rounded,
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'اكتب اسم التمرين';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _englishNameController,
              textInputAction: TextInputAction.next,
              decoration: AppTheme.inputDecoration(context, label: 'الاسم الإنجليزي (اختياري)', hint: 'Push-up', prefixIcon: Icons.translate_rounded),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              textInputAction: TextInputAction.next,
              decoration: AppTheme.inputDecoration(context, label: 'الفئة', hint: 'صدر، ظهر، أرجل...', prefixIcon: Icons.category_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetedMusclesController,
              textInputAction: TextInputAction.next,
              decoration: AppTheme.inputDecoration(context, label: 'العضلات الرئيسية', hint: 'الصدر، الترايسبس', prefixIcon: Icons.fitness_center_rounded),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _secondaryMusclesController,
              textInputAction: TextInputAction.next,
              decoration: AppTheme.inputDecoration(context, label: 'العضلات الثانوية', hint: 'الكتف، البطن', prefixIcon: Icons.sports_gymnastics_rounded),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              decoration: AppTheme.inputDecoration(context, label: 'وصف التمرين (اختياري)', hint: 'طريقة أداء التمرين...', prefixIcon: Icons.notes_rounded),
            ),
            const SizedBox(height: 20),
            const Text(
              'نوع الجولة',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _ModeChip(
                  label: 'عدّات',
                  icon: Icons.repeat_rounded,
                  selected: !_timed,
                  onTap: () => setState(() => _timed = false),
                ),
                const SizedBox(width: 10),
                _ModeChip(
                  label: 'مؤقت (ثبات)',
                  icon: Icons.timer_outlined,
                  selected: _timed,
                  onTap: () => setState(() => _timed = true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _NumberStepper(
              label: 'عدد الجولات',
              valueText: '$_sets',
              onMinus: _sets > 1 ? () => setState(() => _sets--) : null,
              onPlus: _sets < 30 ? () => setState(() => _sets++) : null,
            ),
            const SizedBox(height: 12),
            if (!_timed)
              _NumberStepper(
                label: 'عدد العدّات في الجولة',
                valueText: '$_reps',
                onMinus: _reps > 1 ? () => setState(() => _reps--) : null,
                onPlus: _reps < 500 ? () => setState(() => _reps++) : null,
              )
            else
              _NumberStepper(
                label: 'مدة الجولة',
                valueText: formatDurationText(_duration),
                onMinus: _duration > 5
                    ? () => setState(() => _duration -= 5)
                    : null,
                onPlus: _duration < 3600
                    ? () => setState(() => _duration += 5)
                    : null,
              ),
            const SizedBox(height: 12),
            _NumberStepper(
              label: 'الراحة بين الجولات',
              valueText: _rest == 0 ? 'بدون' : formatDurationText(_rest),
              onMinus: _rest > 0
                  ? () => setState(() => _rest = _rest - 5 < 0 ? 0 : _rest - 5)
                  : null,
              onPlus: _rest < 600 ? () => setState(() => _rest += 5) : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _noteController,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              decoration: AppTheme.inputDecoration(
                context,
                label: 'ملاحظة (اختياري)',
                hint: 'مثال: حافظ على استقامة الظهر',
                prefixIcon: Icons.notes_rounded,
              ),
            ),
            const SizedBox(height: 20),
            SoftCard(
              child: Row(
                children: <Widget>[
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${preview.summary}\n${preview.restLabel}',
                      style: TextStyle(
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(_isEdit ? 'حفظ التعديل' : 'إضافة التمرين'),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر اختيار نوع الجولة (عدّات / مؤقت).
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    Key? key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color fg = selected ? Colors.white : scheme.onSurfaceVariant;
    return Expanded(
      child: Material(
        color: selected ? AppColors.accent : AppTheme.surfaceHigh(context),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w800, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// حقل رقمي بأزرار زائد وناقص. الزر المعطّل يظهر باهتاً.
class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    Key? key,
    required this.label,
    required this.valueText,
    required this.onMinus,
    required this.onPlus,
  }) : super(key: key);

  final String label;
  final String valueText;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _RoundButton(icon: Icons.remove_rounded, onTap: onMinus),
          const SizedBox(width: 10),
          _RoundButton(icon: Icons.add_rounded, onTap: onPlus),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({Key? key, required this.icon, required this.onTap})
      : super(key: key);

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppTheme.surfaceHigh(context),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 24,
            color: enabled
                ? scheme.onSurface
                : scheme.onSurfaceVariant.withOpacity(0.35),
          ),
        ),
      ),
    );
  }
}
