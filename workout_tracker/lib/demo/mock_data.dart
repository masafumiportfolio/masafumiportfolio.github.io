/// デモ用モックデータ
class MockSession {
  final String id;
  final String title;
  final DateTime date;
  final int durationMinutes;
  final List<MockExercise> exercises;

  const MockSession({
    required this.id,
    required this.title,
    required this.date,
    required this.durationMinutes,
    required this.exercises,
  });
}

class MockExercise {
  final String name;
  final String category;
  final List<MockSet> sets;

  const MockExercise({
    required this.name,
    required this.category,
    required this.sets,
  });
}

class MockSet {
  final double weightKg;
  final int reps;

  const MockSet({required this.weightKg, required this.reps});
}

class MockProgressPoint {
  final DateTime date;
  final double weightKg;

  const MockProgressPoint({required this.date, required this.weightKg});
}

final mockSessions = [
  MockSession(
    id: '1',
    title: '胸・三頭筋',
    date: DateTime(2026, 3, 13),
    durationMinutes: 60,
    exercises: [
      MockExercise(name: 'ベンチプレス', category: '胸', sets: [
        MockSet(weightKg: 60, reps: 10),
        MockSet(weightKg: 65, reps: 8),
        MockSet(weightKg: 65, reps: 6),
      ]),
      MockExercise(name: 'インクラインベンチプレス', category: '胸', sets: [
        MockSet(weightKg: 50, reps: 10),
        MockSet(weightKg: 50, reps: 8),
      ]),
      MockExercise(name: 'トライセプスプレスダウン', category: '腕', sets: [
        MockSet(weightKg: 30, reps: 12),
        MockSet(weightKg: 30, reps: 10),
        MockSet(weightKg: 32.5, reps: 8),
      ]),
    ],
  ),
  MockSession(
    id: '2',
    title: '背中・二頭筋',
    date: DateTime(2026, 3, 11),
    durationMinutes: 70,
    exercises: [
      MockExercise(name: 'デッドリフト', category: '背中', sets: [
        MockSet(weightKg: 100, reps: 5),
        MockSet(weightKg: 110, reps: 5),
        MockSet(weightKg: 110, reps: 4),
      ]),
      MockExercise(name: 'ラットプルダウン', category: '背中', sets: [
        MockSet(weightKg: 60, reps: 10),
        MockSet(weightKg: 65, reps: 8),
        MockSet(weightKg: 65, reps: 8),
      ]),
      MockExercise(name: 'バーベルカール', category: '腕', sets: [
        MockSet(weightKg: 30, reps: 10),
        MockSet(weightKg: 30, reps: 10),
      ]),
    ],
  ),
  MockSession(
    id: '3',
    title: '脚の日',
    date: DateTime(2026, 3, 9),
    durationMinutes: 55,
    exercises: [
      MockExercise(name: 'スクワット', category: '脚', sets: [
        MockSet(weightKg: 80, reps: 10),
        MockSet(weightKg: 90, reps: 8),
        MockSet(weightKg: 90, reps: 6),
      ]),
      MockExercise(name: 'レッグプレス', category: '脚', sets: [
        MockSet(weightKg: 120, reps: 12),
        MockSet(weightKg: 130, reps: 10),
      ]),
    ],
  ),
  MockSession(
    id: '4',
    title: '肩の日',
    date: DateTime(2026, 3, 6),
    durationMinutes: 50,
    exercises: [
      MockExercise(name: 'ショルダープレス', category: '肩', sets: [
        MockSet(weightKg: 40, reps: 10),
        MockSet(weightKg: 45, reps: 8),
        MockSet(weightKg: 45, reps: 6),
      ]),
    ],
  ),
];

/// 種目別の進捗データ（デモ用）
final mockProgress = {
  'ベンチプレス': [
    MockProgressPoint(date: DateTime(2026, 2, 1), weightKg: 55),
    MockProgressPoint(date: DateTime(2026, 2, 8), weightKg: 57.5),
    MockProgressPoint(date: DateTime(2026, 2, 15), weightKg: 57.5),
    MockProgressPoint(date: DateTime(2026, 2, 22), weightKg: 60),
    MockProgressPoint(date: DateTime(2026, 3, 1), weightKg: 60),
    MockProgressPoint(date: DateTime(2026, 3, 9), weightKg: 62.5),
    MockProgressPoint(date: DateTime(2026, 3, 13), weightKg: 65),
  ],
  'スクワット': [
    MockProgressPoint(date: DateTime(2026, 2, 1), weightKg: 70),
    MockProgressPoint(date: DateTime(2026, 2, 10), weightKg: 75),
    MockProgressPoint(date: DateTime(2026, 2, 20), weightKg: 80),
    MockProgressPoint(date: DateTime(2026, 3, 1), weightKg: 82.5),
    MockProgressPoint(date: DateTime(2026, 3, 9), weightKg: 90),
  ],
  'デッドリフト': [
    MockProgressPoint(date: DateTime(2026, 2, 5), weightKg: 90),
    MockProgressPoint(date: DateTime(2026, 2, 14), weightKg: 100),
    MockProgressPoint(date: DateTime(2026, 2, 22), weightKg: 100),
    MockProgressPoint(date: DateTime(2026, 3, 11), weightKg: 110),
  ],
};

/// デモ用：今週の統計
const mockWeeklyStats = {
  'sessions': 3,
  'totalSets': 24,
  'streak': 5,
};

/// デモ用：トレーニングがあった日
final mockTrainingDays = {
  DateTime(2026, 3, 6),
  DateTime(2026, 3, 9),
  DateTime(2026, 3, 11),
  DateTime(2026, 3, 13),
};
