import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_session.dart';

class FirestoreService {
  static final _col = FirebaseFirestore.instance.collection('sessions');

  static Future<void> saveSession(ClassSession session) async {
    await _col.doc(session.id).set(session.toMap());
  }

  static Future<void> updateSession(ClassSession session) async {
    await _col.doc(session.id).update(session.toMap());
  }

  static Future<List<ClassSession>> getAllSessions() async {
    final snapshot = await _col.orderBy('checkInTime', descending: true).get();
    return snapshot.docs
        .map((doc) => ClassSession.fromMap(doc.data()))
        .toList();
  }
}
