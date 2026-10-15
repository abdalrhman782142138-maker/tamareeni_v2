import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';
import '../models/program.dart';
import '../models/session_log.dart';

/// خدمة الحفظ المحلي. تحتفظ بالبرامج وسجل الجلسات والإعدادات في الذاكرة،
/// وتحفظها في الجوال بعد كل تعديل، وتُبلغ الواجهات عند أي تغيير.
class StorageService extends ChangeNotifier {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _kPrograms = 'programs_v1';
  static const String _kLogs = 'logs_v1';
  static const String _kSettings = 'settings_v1';

  SharedPreferences? _prefs;
  bool _ready = false;

  List<Program> _programs = <Program>[];
  List<SessionLog> _logs = <SessionLog>[];

  // الإعدادات
  ThemeMode _themeMode = ThemeMode.dark;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  bool get isReady => _ready;
  ThemeMode get themeMode => _themeMode;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  List<Program> get programs => List<Program>.unmodifiable(_programs);
  List<SessionLog> get logs => List<SessionLog>.unmodifiable(_logs);

  // ------------------------------------------------------------
  // التحميل
  // ------------------------------------------------------------

  Future<void> init() async {
    if (_ready) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    final bool firstRun = !prefs.containsKey(_kPrograms);

    _programs = _decodeList<Program>(
      prefs.getString(_kPrograms),
      (Map<String, dynamic> m) => Program.fromJson(m),
    );
    _logs = _decodeList<SessionLog>(
      prefs.getString(_kLogs),
      (Map<String, dynamic> m) => SessionLog.fromJson(m),
    );
    _loadSettings(prefs.getString(_kSettings));

    if (firstRun) {
      _programs = <Program>[_sampleProgram()];
      await _savePrograms();
    }

    _ready = true;
    notifyListeners();
  }

  List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List<T> result = <T>[];
    if (raw == null || raw.isEmpty) return result;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final dynamic item in decoded) {
          if (item is Map) {
            result.add(fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
    } catch (_) {
      // بيانات تالفة: نبدأ بقائمة فارغة بدل أن يتعطل التطبيق.
    }
    return result;
  }

  void _loadSettings(String? raw) {
    if (raw == null || raw.isEmpty) return;
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is Map) {
        final String mode = (decoded['themeMode'] ?? 'dark').toString();
        _themeMode = mode == 'light'
            ? ThemeMode.light
            : (mode == 'system' ? ThemeMode.system : ThemeMode.dark);
        _soundEnabled = decoded['sound'] != false;
        _vibrationEnabled = decoded['vibration'] != false;
      }
    } catch (_) {
      // نتجاهل ونبقي الإعدادات الافتراضية.
    }
  }

  /// برنامج تجريبي يظهر عند أول تشغيل ليرى المستخدم الشكل، ويمكنه حذفه.
  Program _sampleProgram() {
    return Program(
      id: Program.newId(),
      name: 'البلانش',
      days: const <int>[6, 1, 3],
      exercises: <Exercise>[
        Exercise(
          id: Exercise.newId(),
          name: 'Planche Lean',
          reps: 0,
          sets: 4,
          durationSeconds: 20,
          restSeconds: 90,
        ),
        Exercise(
          id: Exercise.newId(),
          name: 'Tuck Planche',
          reps: 0,
          sets: 5,
          durationSeconds: 10,
          restSeconds: 90,
        ),
        Exercise(
          id: Exercise.newId(),
          name: 'Pseudo Planche Push-ups',
          reps: 8,
          sets: 4,
          durationSeconds: 0,
          restSeconds: 75,
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // الحفظ
  // ------------------------------------------------------------

  Future<void> _savePrograms() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return;
    final String json = jsonEncode(
      _programs.map((Program p) => p.toJson()).toList(),
    );
    await prefs.setString(_kPrograms, json);
  }

  Future<void> _saveLogs() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return;
    final String json = jsonEncode(
      _logs.map((SessionLog l) => l.toJson()).toList(),
    );
    await prefs.setString(_kLogs, json);
  }

  Future<void> _saveSettings() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return;
    final String mode = _themeMode == ThemeMode.light
        ? 'light'
        : (_themeMode == ThemeMode.system ? 'system' : 'dark');
    final String json = jsonEncode(<String, dynamic>{
      'themeMode': mode,
      'sound': _soundEnabled,
      'vibration': _vibrationEnabled,
    });
    await prefs.setString(_kSettings, json);
  }

  // ------------------------------------------------------------
  // البرامج
  // ------------------------------------------------------------

  Program? programById(String id) {
    for (final Program p in _programs) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// البرامج المجدولة في يوم معيّن (DateTime.weekday).
  List<Program> programsForWeekday(int weekday) {
    return _programs.where((Program p) => p.trainsOn(weekday)).toList();
  }

  Future<void> addProgram(Program program) async {
    _programs = <Program>[..._programs, program];
    notifyListeners();
    await _savePrograms();
  }

  Future<void> updateProgram(Program program) async {
    _programs = _programs
        .map((Program p) => p.id == program.id ? program : p)
        .toList();
    notifyListeners();
    await _savePrograms();
  }

  /// حذف برنامج. سجل الجلسات القديمة يبقى محفوظاً.
  Future<void> deleteProgram(String id) async {
    _programs = _programs.where((Program p) => p.id != id).toList();
    notifyListeners();
    await _savePrograms();
  }

  // ------------------------------------------------------------
  // سجل الجلسات
  // ------------------------------------------------------------

  Future<void> addLog(SessionLog log) async {
    _logs = <SessionLog>[..._logs, log];
    notifyListeners();
    await _saveLogs();
  }

  Future<void> addLogs(List<SessionLog> newLogs) async {
    if (newLogs.isEmpty) return;
    _logs = <SessionLog>[..._logs, ...newLogs];
    notifyListeners();
    await _saveLogs();
  }

  /// يستبدل السجل إذا كان موجوداً بنفس المعرّف، وإلا يضيفه.
  /// تستخدمه شاشة التمرين لحفظ كل جولة فور انتهائها.
  Future<void> upsertLog(SessionLog log) async {
    final List<SessionLog> updated = List<SessionLog>.from(_logs);
    final int index = updated.indexWhere((SessionLog l) => l.id == log.id);
    if (index >= 0) {
      updated[index] = log;
    } else {
      updated.add(log);
    }
    _logs = updated;
    notifyListeners();
    await _saveLogs();
  }

  Future<void> deleteLog(String id) async {
    _logs = _logs.where((SessionLog l) => l.id != id).toList();
    notifyListeners();
    await _saveLogs();
  }

  Future<void> clearLogs() async {
    _logs = <SessionLog>[];
    notifyListeners();
    await _saveLogs();
  }

  /// أحدث [count] سجلات (الأحدث أولاً).
  List<SessionLog> latestLogs(int count) {
    final List<SessionLog> sorted = List<SessionLog>.from(_logs)
      ..sort((SessionLog a, SessionLog b) => b.date.compareTo(a.date));
    if (sorted.length <= count) return sorted;
    return sorted.sublist(0, count);
  }

  /// سجلات تمرين معيّن مرتبة من الأقدم إلى الأحدث.
  List<SessionLog> logsForExercise(String exerciseKey) {
    final List<SessionLog> list = _logs
        .where((SessionLog l) => l.exerciseKey == exerciseKey)
        .toList();
    list.sort((SessionLog a, SessionLog b) => a.date.compareTo(b.date));
    return list;
  }

  /// أسماء التمارين التي لها سجلات، الأحدث نشاطاً أولاً.
  List<String> loggedExerciseKeys() {
    final Map<String, DateTime> latest = <String, DateTime>{};
    for (final SessionLog l in _logs) {
      final String key = l.exerciseKey;
      if (key.isEmpty) continue;
      final DateTime? current = latest[key];
      if (current == null || l.date.isAfter(current)) {
        latest[key] = l.date;
      }
    }
    final List<String> keys = latest.keys.toList();
    keys.sort((String a, String b) => latest[b]!.compareTo(latest[a]!));
    return keys;
  }

  // ------------------------------------------------------------
  // إحصائيات
  // ------------------------------------------------------------

  Set<String> get trainedDayKeys {
    final Set<String> keys = <String>{};
    for (final SessionLog l in _logs) {
      keys.add(l.dayKey);
    }
    return keys;
  }

  static DateTime _previousDay(DateTime d) {
    return DateTime(d.year, d.month, d.day - 1);
  }

  /// عدد الأيام المتتالية التي تمرّنت فيها (تنتهي اليوم أو أمس).
  int get currentStreak {
    final Set<String> days = trainedDayKeys;
    DateTime cursor = DateTime.now();
    if (!days.contains(SessionLog.dayKeyFor(cursor))) {
      cursor = _previousDay(cursor);
    }
    int streak = 0;
    while (days.contains(SessionLog.dayKeyFor(cursor))) {
      streak++;
      cursor = _previousDay(cursor);
    }
    return streak;
  }

  /// عدد الأيام التي تمرّنت فيها خلال آخر [days] يوماً (تشمل اليوم).
  int trainedDaysInLast(int days) {
    final Set<String> keys = trainedDayKeys;
    DateTime cursor = DateTime.now();
    int count = 0;
    for (int i = 0; i < days; i++) {
      if (keys.contains(SessionLog.dayKeyFor(cursor))) count++;
      cursor = _previousDay(cursor);
    }
    return count;
  }

  /// هل تم تسجيل تمرين اليوم؟
  bool get trainedToday {
    return trainedDayKeys.contains(SessionLog.dayKeyFor(DateTime.now()));
  }

  // ------------------------------------------------------------
  // الإعدادات
  // ------------------------------------------------------------

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    notifyListeners();
    await _saveSettings();
  }

  /// مسح كل البرامج والسجل (تبقى الإعدادات).
  Future<void> resetAllData() async {
    _programs = <Program>[];
    _logs = <SessionLog>[];
    notifyListeners();
    await _savePrograms();
    await _saveLogs();
  }
}
