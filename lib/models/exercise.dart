/// تنسيق الثواني كساعة مؤقت: 01:30
String formatClock(int seconds) {
  final int total = seconds < 0 ? 0 : seconds;
  final int m = total ~/ 60;
  final int s = total % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// تنسيق الثواني كنص عربي مختصر: 45 ث / 2 د / 1 د 30 ث
String formatDurationText(int seconds) {
  if (seconds <= 0) return '0 ث';
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  if (m == 0) return '$s ث';
  if (s == 0) return '$m د';
  return '$m د $s ث';
}

int _asInt(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// تمرين واحد: اسمه، وعدّاته، وجولاته، ومدة الجولة، والراحة بين الجولات.
///
/// - إذا كانت [durationSeconds] أكبر من صفر فالجولة تُنفَّذ بمؤقت (مثل الثبات).
/// - وإذا كانت صفراً فالجولة تُنفَّذ بالعدّات ([reps]).
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    this.reps = 10,
    this.sets = 3,
    this.durationSeconds = 0,
    this.restSeconds = 60,
    this.note = '',
    this.nameArabic = '',
    this.nameEnglish = '',
    this.category = 'عام',
    this.targetedMuscles = const <String>[],
    this.secondaryMuscles = const <String>[],
    this.description = '',
    this.imagePath = '',
  });

  final String id;
  /// الاسم الأصلي الذي تستخدمه واجهات التطبيق الحالية.
  final String name;
  final int reps;
  final int sets;
  final int durationSeconds;
  final int restSeconds;
  final String note;

  /// بيانات خريطة العضلات، اختيارية لتوافق بيانات الإصدار السابق.
  final String nameArabic;
  final String nameEnglish;
  final String category;
  final List<String> targetedMuscles;
  final List<String> secondaryMuscles;
  final String description;
  final String imagePath;

  String get displayNameArabic => nameArabic.trim().isEmpty ? name : nameArabic;
  String get effectiveDescription => description.trim().isEmpty ? note : description;

  static int _seq = 0;
  static String newId() {
    _seq++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }

  bool get isTimed => durationSeconds > 0;

  String get summary {
    final List<String> parts = <String>[];
    parts.add('$sets جولات');
    if (reps > 0) parts.add('$reps عدّات');
    if (durationSeconds > 0) parts.add('${formatDurationText(durationSeconds)} للجولة');
    return parts.join(' • ');
  }

  String get restLabel => restSeconds <= 0 ? 'بدون راحة' : 'راحة ${formatDurationText(restSeconds)}';

  int get estimatedSeconds {
    final int safeSets = sets < 1 ? 1 : sets;
    final int work = isTimed ? durationSeconds * safeSets : 0;
    final int rest = restSeconds * (safeSets - 1);
    return work + rest;
  }

  Exercise copyWith({
    String? id,
    String? name,
    int? reps,
    int? sets,
    int? durationSeconds,
    int? restSeconds,
    String? note,
    String? nameArabic,
    String? nameEnglish,
    String? category,
    List<String>? targetedMuscles,
    List<String>? secondaryMuscles,
    String? description,
    String? imagePath,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      note: note ?? this.note,
      nameArabic: nameArabic ?? this.nameArabic,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      category: category ?? this.category,
      targetedMuscles: targetedMuscles ?? this.targetedMuscles,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'reps': reps,
    'sets': sets,
    'durationSeconds': durationSeconds,
    'restSeconds': restSeconds,
    'note': note,
    'nameArabic': nameArabic,
    'nameEnglish': nameEnglish,
    'category': category,
    'targetedMuscles': targetedMuscles,
    'secondaryMuscles': secondaryMuscles,
    'description': description,
    'imagePath': imagePath,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final String rawId = (json['id'] ?? '').toString();
    List<String> readStrings(dynamic value) => value is List
        ? value.map((dynamic item) => item.toString()).toList()
        : <String>[];
    final String oldName = (json['name'] ?? '').toString();
    final String arabicName = (json['nameArabic'] ?? '').toString();
    return Exercise(
      id: rawId.isEmpty ? newId() : rawId,
      name: oldName.isNotEmpty ? oldName : arabicName,
      reps: _asInt(json['reps'], 10),
      sets: _asInt(json['sets'], 3),
      durationSeconds: _asInt(json['durationSeconds'], 0),
      restSeconds: _asInt(json['restSeconds'], 60),
      note: (json['note'] ?? '').toString(),
      nameArabic: arabicName,
      nameEnglish: (json['nameEnglish'] ?? '').toString(),
      category: (json['category'] ?? 'عام').toString(),
      targetedMuscles: readStrings(json['targetedMuscles']),
      secondaryMuscles: readStrings(json['secondaryMuscles']),
      description: (json['description'] ?? '').toString(),
      imagePath: (json['imagePath'] ?? '').toString(),
    );
  }
}
