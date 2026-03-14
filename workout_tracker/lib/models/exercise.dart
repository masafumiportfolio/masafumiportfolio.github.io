import 'package:drift/drift.dart';

/// 種目マスタ
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()(); // 胸・背中・脚・肩・腕・腹筋・その他
  TextColumn get memo => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// ワークアウトセッション（1回のトレーニング）
class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text().nullable()(); // 例:「胸の日」
  DateTimeColumn get date => dateTime()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get memo => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// セット記録（1セッション内の各セット）
class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get setNumber => integer()();
  RealColumn get weightKg => real()(); // 重量(kg)
  IntColumn get reps => integer()();   // 回数
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get memo => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
