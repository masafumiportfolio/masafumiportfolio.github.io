import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'exercise.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Exercises, WorkoutSessions, WorkoutSets])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ---- Exercises ----
  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Future<List<Exercise>> getExercisesByCategory(String category) =>
      (select(exercises)..where((e) => e.category.equals(category))).get();

  Future<String> insertExercise(ExercisesCompanion entry) async {
    await into(exercises).insert(entry);
    return entry.id.value;
  }

  // ---- WorkoutSessions ----
  Future<List<WorkoutSession>> getSessionsByUserId(String userId) =>
      (select(workoutSessions)
            ..where((s) => s.userId.equals(userId))
            ..orderBy([(s) => OrderingTerm.desc(s.date)]))
          .get();

  Future<List<WorkoutSession>> getSessionsByDate(
          String userId, DateTime date) =>
      (select(workoutSessions)
            ..where((s) =>
                s.userId.equals(userId) &
                s.date.isBiggerOrEqualValue(
                    DateTime(date.year, date.month, date.day)) &
                s.date.isSmallerThanValue(
                    DateTime(date.year, date.month, date.day + 1))))
          .get();

  Future<String> insertSession(WorkoutSessionsCompanion entry) async {
    await into(workoutSessions).insert(entry);
    return entry.id.value;
  }

  Future<void> updateSession(WorkoutSessionsCompanion entry) =>
      (update(workoutSessions)..where((s) => s.id.equals(entry.id.value)))
          .write(entry);

  Future<void> deleteSession(String id) =>
      (delete(workoutSessions)..where((s) => s.id.equals(id))).go();

  // ---- WorkoutSets ----
  Future<List<WorkoutSet>> getSetsForSession(String sessionId) =>
      (select(workoutSets)
            ..where((s) => s.sessionId.equals(sessionId))
            ..orderBy([
              (s) => OrderingTerm.asc(s.exerciseId),
              (s) => OrderingTerm.asc(s.setNumber),
            ]))
          .get();

  Future<List<WorkoutSet>> getSetsForExercise(String exerciseId) =>
      (select(workoutSets)..where((s) => s.exerciseId.equals(exerciseId)))
          .get();

  Future<String> insertSet(WorkoutSetsCompanion entry) async {
    await into(workoutSets).insert(entry);
    return entry.id.value;
  }

  Future<void> updateSet(WorkoutSetsCompanion entry) =>
      (update(workoutSets)..where((s) => s.id.equals(entry.id.value)))
          .write(entry);

  Future<void> deleteSet(String id) =>
      (delete(workoutSets)..where((s) => s.id.equals(id))).go();

  Future<void> deleteSetsForSession(String sessionId) =>
      (delete(workoutSets)..where((s) => s.sessionId.equals(sessionId))).go();

  // ---- 進捗クエリ ----
  /// 種目ごとの最高重量を取得
  Future<double?> getMaxWeightForExercise(String exerciseId) async {
    final query = selectOnly(workoutSets)
      ..addColumns([workoutSets.weightKg.max()])
      ..where(workoutSets.exerciseId.equals(exerciseId));
    final result = await query.getSingleOrNull();
    return result?.read(workoutSets.weightKg.max());
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'workout_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
