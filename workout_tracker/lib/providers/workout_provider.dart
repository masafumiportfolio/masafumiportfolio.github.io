import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/app_database.dart';
import '../services/firestore_service.dart';
import 'database_provider.dart';

const _uuid = Uuid();

/// Firebase Auth の現在のユーザーを監視
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 全セッション一覧（ログインユーザー）
final workoutSessionsProvider =
    FutureProvider<List<WorkoutSession>>((ref) async {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  final db = ref.watch(databaseProvider);
  return db.getSessionsByUserId(user.uid);
});

/// ワークアウト実施日の Set<DateTime>（カレンダー表示用）
final workoutDatesProvider = FutureProvider<Set<DateTime>>((ref) async {
  final sessions = await ref.watch(workoutSessionsProvider.future);
  return sessions
      .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
      .toSet();
});

/// セッションのセット一覧
final setsForSessionProvider =
    FutureProvider.family<List<WorkoutSet>, String>((ref, sessionId) async {
  final db = ref.watch(databaseProvider);
  return db.getSetsForSession(sessionId);
});

/// セッションのセット数
final setCountForSessionProvider =
    FutureProvider.family<int, String>((ref, sessionId) async {
  final db = ref.watch(databaseProvider);
  return db.getSetCountForSession(sessionId);
});

/// 1セットの記録データ
typedef SetRecord = ({double weight, int reps, bool isCompleted});

/// ワークアウト保存・削除を担う Notifier
class WorkoutNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> saveSession({
    required DateTime date,
    String? title,
    int? durationMinutes,
    String? memo,
    required Map<String, List<SetRecord>> exerciseSets,
  }) async {
    state = const AsyncLoading();
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) throw Exception('ログインが必要です');

      final db = ref.read(databaseProvider);
      final sessionId = _uuid.v4();

      await db.insertSession(WorkoutSessionsCompanion(
        id: Value(sessionId),
        userId: Value(user.uid),
        title: Value(title),
        date: Value(date),
        durationMinutes: Value(durationMinutes),
        memo: Value(memo),
      ));

      for (final entry in exerciseSets.entries) {
        final exerciseId = entry.key;
        final sets = entry.value;
        for (int i = 0; i < sets.length; i++) {
          final s = sets[i];
          await db.insertSet(WorkoutSetsCompanion(
            id: Value(_uuid.v4()),
            sessionId: Value(sessionId),
            exerciseId: Value(exerciseId),
            setNumber: Value(i + 1),
            weightKg: Value(s.weight),
            reps: Value(s.reps),
            isCompleted: Value(s.isCompleted),
          ));
        }
      }

      // Firestoreに非同期同期（オフライン時は無視）
      try {
        final savedSets = await db.getSetsForSession(sessionId);
        final sessions = await db.getSessionsByUserId(user.uid);
        final session = sessions.firstWhere((s) => s.id == sessionId);
        await FirestoreService().syncSession(user.uid, session, savedSets);
      } catch (_) {
        // ネットワークエラーはローカル保存済みなので無視
      }

      ref.invalidate(workoutSessionsProvider);
      ref.invalidate(workoutDatesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteSession(String sessionId) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final db = ref.read(databaseProvider);
    await db.deleteSetsForSession(sessionId);
    await db.deleteSession(sessionId);

    // Firestoreからも削除
    try {
      await FirestoreService().deleteSession(user.uid, sessionId);
    } catch (_) {}

    ref.invalidate(workoutSessionsProvider);
    ref.invalidate(workoutDatesProvider);
  }
}

final workoutNotifierProvider =
    AsyncNotifierProvider<WorkoutNotifier, void>(WorkoutNotifier.new);
