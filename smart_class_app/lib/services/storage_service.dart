import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_session.dart'; // also imports SessionStatus

class StorageService {
  static const _sessionsKey = 'class_sessions';
  static const _lastStudentIdKey = 'last_student_id';

  static Future<List<ClassSession>> getAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_sessionsKey) ?? [];
    return raw
        .map((s) => ClassSession.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> saveSession(ClassSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getAllSessions();
    sessions.add(session);
    await prefs.setStringList(
      _sessionsKey,
      sessions.map((s) => jsonEncode(s.toMap())).toList(),
    );
  }

  static Future<void> updateSession(ClassSession updated) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getAllSessions();
    final index = sessions.indexWhere((s) => s.id == updated.id);
    if (index != -1) sessions[index] = updated;
    await prefs.setStringList(
      _sessionsKey,
      sessions.map((s) => jsonEncode(s.toMap())).toList(),
    );
  }

  /// Returns the most recent session with status [SessionStatus.checkedIn].
  static Future<ClassSession?> getLatestSession() => getLatestOpenSession();

  /// Returns the most recent session with status [SessionStatus.checkedIn].
  static Future<ClassSession?> getLatestOpenSession() async {
    final sessions = await getAllSessions();
    final active = sessions
        .where((s) => s.status == SessionStatus.checkedIn)
        .toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return active.first;
  }

  static Future<void> saveLastStudentId(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastStudentIdKey, studentId);
  }

  static Future<String?> getLastStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_lastStudentIdKey);
    if (id == null || id.trim().isEmpty) return null;
    return id;
  }
}
