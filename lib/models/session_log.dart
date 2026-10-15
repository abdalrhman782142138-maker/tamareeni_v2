int _asInt(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// نتيجة جولة واحدة: كم عدّة أنجزت، وكم ثانية استغرقت (أو ثبتّ).
class SetResult {
  const SetResult({this.reps = 0, this.seconds = 0});

  final int reps;
  final int seconds;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'reps': reps, 'seconds': seconds};
  }

  factory SetResult.fromJson(Map<String, dynamic> json) {
    return SetResult(
      reps: _asInt(json['reps'], 0),
      seconds: _asInt(json['seconds'], 0),
    );
  }
}

/// سجل تنفيذ تمرين واحد في يوم معيّن.
/// كل سجل يمثل مرة واحدة نفّذت فيها هذا التمرين بجولاته.
class SessionLog {
  const SessionLog({
    required this.id,
    required this.date,
    required this.exerciseName,
    this.programId = '',
    this.programName = '',
    this.isTimed = false,
    this.targetSets = 0,
    this.results = const <SetResult>[],
  });

  final String id;
  final DateTime date;
  final String exerciseName;
  final String programId;
  final String programName;

  /// هل كان التمرين بمؤقت (ثبات) أم بعدّات؟
  final bool isTimed;

  /// عدد الجولات المخطط لها وقت التنفيذ.
  final int targetSets;
  final List<SetResult> results;

  static int _seq = 0;

  /// معرّف فريد للسجل الجديد.
  static String newId() {
    _seq++;
    return 'l${DateTime.now().microsecondsSinceEpoch}_$_seq';
  }

  /// مفتاح تجميع التمرين في جدول التطور (الاسم بعد تنظيف المسافات).
  static String keyFor(String name) {
    return name.trim().split(RegExp(r'\s+')).join(' ');
  }

  /// مفتاح اليوم بصيغة yyyy-MM-dd.
  static String dayKeyFor(DateTime d) {
    final String m = d.month.toString().padLeft(2, '0');
    final String day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String get exerciseKey => keyFor(exerciseName);

  String get dayKey => dayKeyFor(date);

  int get setsDone => results.length;

  /// هل أكملت كل الجولات المخططة؟
  bool get completed => targetSets > 0 && setsDone >= targetSets;

  int get totalReps {
    int total = 0;
    for (final SetResult r in results) {
      total += r.reps;
    }
    return total;
  }

  int get totalSeconds {
    int total = 0;
    for (final SetResult r in results) {
      total += r.seconds;
    }
    return total;
  }

  int get bestReps {
    int best = 0;
    for (final SetResult r in results) {
      if (r.reps > best) best = r.reps;
    }
    return best;
  }

  int get bestSeconds {
    int best = 0;
    for (final SetResult r in results) {
      if (r.seconds > best) best = r.seconds;
    }
    return best;
  }

  /// القيمة التي نرسمها في الرسم البياني:
  /// أطول ثبات (ثواني) للتمرين المؤقت، أو أفضل عدد عدّات في جولة.
  int get metricValue => isTimed ? bestSeconds : bestReps;

  SessionLog copyWith({
    String? id,
    DateTime? date,
    String? exerciseName,
    String? programId,
    String? programName,
    bool? isTimed,
    int? targetSets,
    List<SetResult>? results,
  }) {
    return SessionLog(
      id: id ?? this.id,
      date: date ?? this.date,
      exerciseName: exerciseName ?? this.exerciseName,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      isTimed: isTimed ?? this.isTimed,
      targetSets: targetSets ?? this.targetSets,
      results: results ?? this.results,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'exerciseName': exerciseName,
      'programId': programId,
      'programName': programName,
      'isTimed': isTimed,
      'targetSets': targetSets,
      'results': results.map((SetResult r) => r.toJson()).toList(),
    };
  }

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    final List<SetResult> parsed = <SetResult>[];
    final dynamic rawResults = json['results'];
    if (rawResults is List) {
      for (final dynamic item in rawResults) {
        if (item is Map) {
          parsed.add(SetResult.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final String rawId = (json['id'] ?? '').toString();
    final DateTime parsedDate =
        DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now();

    return SessionLog(
      id: rawId.isEmpty ? newId() : rawId,
      date: parsedDate,
      exerciseName: (json['exerciseName'] ?? '').toString(),
      programId: (json['programId'] ?? '').toString(),
      programName: (json['programName'] ?? '').toString(),
      isTimed: json['isTimed'] == true,
      targetSets: _asInt(json['targetSets'], 0),
      results: parsed,
    );
  }
}
