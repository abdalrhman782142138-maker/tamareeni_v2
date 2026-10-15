import 'exercise.dart';

/// أسماء أيام الأسبوع. المفتاح هو DateTime.weekday
/// (الاثنين = 1 ... الأحد = 7).
const Map<int, String> kDayNames = <int, String>{
  1: 'الاثنين',
  2: 'الثلاثاء',
  3: 'الأربعاء',
  4: 'الخميس',
  5: 'الجمعة',
  6: 'السبت',
  7: 'الأحد',
};

/// ترتيب عرض الأيام في الواجهة العربية (يبدأ بالسبت).
const List<int> kWeekOrder = <int>[6, 7, 1, 2, 3, 4, 5];

/// برنامج تمارين مثل «البلانش» أو «الظهر»: اسمه وتمارينه وأيام تنفيذه.
class Program {
  const Program({
    required this.id,
    required this.name,
    this.exercises = const <Exercise>[],
    this.days = const <int>[],
    this.note = '',
  });

  final String id;
  final String name;
  final List<Exercise> exercises;

  /// أيام التمرين بصيغة DateTime.weekday (1 إلى 7).
  final List<int> days;
  final String note;

  static int _seq = 0;

  /// معرّف فريد للبرنامج الجديد.
  static String newId() {
    _seq++;
    return 'p${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }

  int get exerciseCount => exercises.length;

  bool get isEmpty => exercises.isEmpty;

  /// هل البرنامج مجدول في هذا اليوم؟
  bool trainsOn(int weekday) => days.contains(weekday);

  /// تقدير المدة الكلية بالثواني لكل تمارين البرنامج.
  int get estimatedSeconds {
    int total = 0;
    for (final Exercise e in exercises) {
      total += e.estimatedSeconds;
    }
    return total;
  }

  /// وصف الأيام مثل: السبت، الاثنين، الأربعاء
  String get daysLabel {
    if (days.isEmpty) return 'بدون أيام محددة';
    if (days.length >= 7) return 'كل يوم';
    final List<String> names = <String>[];
    for (final int d in kWeekOrder) {
      if (days.contains(d)) names.add(kDayNames[d] ?? '');
    }
    return names.join('، ');
  }

  Program copyWith({
    String? id,
    String? name,
    List<Exercise>? exercises,
    List<int>? days,
    String? note,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      days: days ?? this.days,
      note: note ?? this.note,
    );
  }

  // ------------------------------------------------------------
  // تعديل قائمة التمارين (تُرجع برنامجاً جديداً دون تغيير الأصل)
  // ------------------------------------------------------------

  Program withExerciseAdded(Exercise exercise) {
    return copyWith(exercises: <Exercise>[...exercises, exercise]);
  }

  Program withExerciseUpdated(Exercise exercise) {
    final List<Exercise> updated = <Exercise>[];
    for (final Exercise e in exercises) {
      updated.add(e.id == exercise.id ? exercise : e);
    }
    return copyWith(exercises: updated);
  }

  Program withExerciseRemoved(String exerciseId) {
    final List<Exercise> updated = <Exercise>[];
    for (final Exercise e in exercises) {
      if (e.id != exerciseId) updated.add(e);
    }
    return copyWith(exercises: updated);
  }

  /// نقل تمرين من موضع إلى آخر (بنفس منطق ReorderableListView).
  Program withExercisesReordered(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= exercises.length) return this;
    int target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target < 0) target = 0;
    if (target >= exercises.length) target = exercises.length - 1;

    final List<Exercise> list = List<Exercise>.from(exercises);
    final Exercise moved = list.removeAt(oldIndex);
    list.insert(target, moved);
    return copyWith(exercises: list);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'note': note,
      'days': days,
      'exercises': exercises.map((Exercise e) => e.toJson()).toList(),
    };
  }

  factory Program.fromJson(Map<String, dynamic> json) {
    final List<Exercise> parsedExercises = <Exercise>[];
    final dynamic rawExercises = json['exercises'];
    if (rawExercises is List) {
      for (final dynamic item in rawExercises) {
        if (item is Map) {
          parsedExercises.add(
            Exercise.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final List<int> parsedDays = <int>[];
    final dynamic rawDays = json['days'];
    if (rawDays is List) {
      for (final dynamic d in rawDays) {
        if (d is num) {
          final int day = d.toInt();
          if (day >= 1 && day <= 7 && !parsedDays.contains(day)) {
            parsedDays.add(day);
          }
        }
      }
    }

    final String rawId = (json['id'] ?? '').toString();
    return Program(
      id: rawId.isEmpty ? newId() : rawId,
      name: (json['name'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      days: parsedDays,
      exercises: parsedExercises,
    );
  }
}
