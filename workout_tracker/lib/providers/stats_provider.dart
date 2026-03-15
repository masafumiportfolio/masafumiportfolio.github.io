import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_database.dart';
import 'database_provider.dart';
import 'workout_provider.dart';

class WeeklyStats {
  final int sessionsCount;
  final int totalSets;
  final int streakDays;

  const WeeklyStats({
    required this.sessionsCount,
    required this.totalSets,
    required this.streakDays,
  });
}

final weeklyStatsProvider = FutureProvider<WeeklyStats>((ref) async {
  final sessions = await ref.watch(workoutSessionsProvider.future);
  final db = ref.watch(databaseProvider);

  final now = DateTime.now();
  // 今週の月曜日（週の開始）
  final weekStart =
      DateTime(now.year, now.month, now.day - (now.weekday - 1));

  final thisWeekSessions =
      sessions.where((s) => !s.date.isBefore(weekStart)).toList();

  int totalSets = 0;
  for (final session in thisWeekSessions) {
    final count = await db.getSetCountForSession(session.id);
    totalSets += count;
  }

  final streak = _calculateStreak(sessions);

  return WeeklyStats(
    sessionsCount: thisWeekSessions.length,
    totalSets: totalSets,
    streakDays: streak,
  );
});

int _calculateStreak(List<WorkoutSession> sessions) {
  if (sessions.isEmpty) return 0;

  final dates = sessions
      .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  final today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  int streak = 0;
  DateTime expected = today;

  for (final date in dates) {
    if (date == expected) {
      streak++;
      expected = expected.subtract(const Duration(days: 1));
    } else if (streak == 0 &&
        date == today.subtract(const Duration(days: 1))) {
      // 今日はまだトレーニングしていないが昨日からのストリーク
      streak++;
      expected = date.subtract(const Duration(days: 1));
    } else if (date.isBefore(expected)) {
      break;
    }
  }

  return streak;
}

/// 種目別・日付別 最高重量推移
typedef ExerciseProgress = ({DateTime date, double maxWeight});

final exerciseProgressProvider = FutureProvider.family<List<ExerciseProgress>,
    String>((ref, exerciseId) async {
  final db = ref.watch(databaseProvider);
  return db.getExerciseProgress(exerciseId);
});
