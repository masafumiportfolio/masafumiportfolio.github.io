import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/app_database.dart';
import 'database_provider.dart';

const _uuid = Uuid();

/// デフォルト種目マスタ
const kDefaultExercises = <String, List<String>>{
  '胸': ['ベンチプレス', 'インクラインベンチプレス', 'ダンベルフライ', 'チェストプレス', 'ディップス'],
  '背中': ['デッドリフト', 'ラットプルダウン', '懸垂', 'ベントオーバーロウ', 'シーテッドロウ'],
  '脚': ['スクワット', 'レッグプレス', 'レッグカール', 'レッグエクステンション', 'カーフレイズ'],
  '肩': ['ショルダープレス', 'サイドレイズ', 'フロントレイズ', 'リアレイズ', 'フェイスプル'],
  '腕': ['バーベルカール', 'ダンベルカール', 'トライセプスプレスダウン', 'スカルクラッシャー'],
  '腹筋': ['クランチ', 'レッグレイズ', 'プランク', 'ロシアンツイスト', 'アブローラー'],
};

Future<void> seedDefaultExercises(AppDatabase db) async {
  for (final entry in kDefaultExercises.entries) {
    for (final name in entry.value) {
      await db.insertExercise(ExercisesCompanion(
        id: Value(_uuid.v4()),
        name: Value(name),
        category: Value(entry.key),
        isCustom: const Value(false),
        createdAt: Value(DateTime.now()),
      ));
    }
  }
}

class ExerciseNotifier extends AsyncNotifier<List<Exercise>> {
  @override
  Future<List<Exercise>> build() async {
    final db = ref.watch(databaseProvider);
    var exercises = await db.getAllExercises();
    if (exercises.isEmpty) {
      await seedDefaultExercises(db);
      exercises = await db.getAllExercises();
    }
    return exercises;
  }

  Future<void> addCustomExercise({
    required String name,
    required String category,
    String? memo,
  }) async {
    final db = ref.read(databaseProvider);
    await db.insertExercise(ExercisesCompanion(
      id: Value(_uuid.v4()),
      name: Value(name),
      category: Value(category),
      memo: Value(memo),
      isCustom: const Value(true),
      createdAt: Value(DateTime.now()),
    ));
    ref.invalidateSelf();
  }

  Future<void> deleteCustomExercise(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteExercise(id);
    ref.invalidateSelf();
  }
}

final exerciseNotifierProvider =
    AsyncNotifierProvider<ExerciseNotifier, List<Exercise>>(
        ExerciseNotifier.new);

/// exerciseId -> Exercise のマップ（画面でのルックアップ用）
final exerciseMapProvider =
    Provider<AsyncValue<Map<String, Exercise>>>((ref) {
  return ref.watch(exerciseNotifierProvider).whenData(
        (list) => {for (final e in list) e.id: e},
      );
});
