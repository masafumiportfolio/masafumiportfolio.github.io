import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_database.dart';

/// Firestore へのクラウド同期を担うサービス
class FirestoreService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessionsRef(String userId) =>
      _db.collection('users').doc(userId).collection('sessions');

  /// セッションと全セットを Firestore へ保存・更新
  Future<void> syncSession(
    String userId,
    WorkoutSession session,
    List<WorkoutSet> sets,
  ) async {
    final sessionRef = _sessionsRef(userId).doc(session.id);

    await sessionRef.set({
      'id': session.id,
      'userId': session.userId,
      'title': session.title,
      'date': Timestamp.fromDate(session.date),
      'durationMinutes': session.durationMinutes,
      'memo': session.memo,
      'syncedAt': FieldValue.serverTimestamp(),
    });

    final batch = _db.batch();
    for (final s in sets) {
      final setRef = sessionRef.collection('sets').doc(s.id);
      batch.set(setRef, {
        'id': s.id,
        'sessionId': s.sessionId,
        'exerciseId': s.exerciseId,
        'setNumber': s.setNumber,
        'weightKg': s.weightKg,
        'reps': s.reps,
        'isCompleted': s.isCompleted,
        'memo': s.memo,
      });
    }
    await batch.commit();
  }

  /// Firestore からセッションを削除（サブコレクション含む）
  Future<void> deleteSession(String userId, String sessionId) async {
    final sessionRef = _sessionsRef(userId).doc(sessionId);

    final setsSnapshot = await sessionRef.collection('sets').get();
    final batch = _db.batch();
    for (final doc in setsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(sessionRef);
    await batch.commit();
  }

  /// Firestore からセッション一覧を取得（バックアップ復元用）
  Future<List<Map<String, dynamic>>> fetchSessions(String userId) async {
    final snapshot = await _sessionsRef(userId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  /// Firestore からセッションのセット一覧を取得
  Future<List<Map<String, dynamic>>> fetchSetsForSession(
      String userId, String sessionId) async {
    final snapshot = await _sessionsRef(userId)
        .doc(sessionId)
        .collection('sets')
        .orderBy('setNumber')
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }
}
