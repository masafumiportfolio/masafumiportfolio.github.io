import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/app_database.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/workout_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('履歴・進捗'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'トレーニング履歴'),
            Tab(text: '種目の進捗'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _WorkoutHistoryTab(),
          _ExerciseProgressTab(),
        ],
      ),
    );
  }
}

// ---- トレーニング履歴タブ ----

class _WorkoutHistoryTab extends ConsumerWidget {
  const _WorkoutHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(workoutSessionsProvider);

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('まだトレーニング記録がありません'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            return _SessionCard(session: sessions[index]);
          },
        );
      },
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final WorkoutSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setCountAsync =
        ref.watch(setCountForSessionProvider(session.id));
    final setCount = setCountAsync.valueOrNull ?? 0;
    final dateStr = DateFormat('yyyy/MM/dd(E)', 'ja').format(session.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E88E5),
          child: Text(
            session.durationMinutes != null
                ? '${session.durationMinutes}'
                : '--',
            style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(session.title ?? 'トレーニング'),
        subtitle: Text('$dateStr  $setCountセット'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey),
          onPressed: () => _confirmDelete(context, ref),
        ),
        onTap: () => _showSessionDetail(context, ref),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: const Text('このトレーニング記録を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(workoutNotifierProvider.notifier)
          .deleteSession(session.id);
    }
  }

  void _showSessionDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SessionDetailSheet(session: session),
    );
  }
}

class _SessionDetailSheet extends ConsumerWidget {
  final WorkoutSession session;

  const _SessionDetailSheet({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(setsForSessionProvider(session.id));
    final exerciseMapAsync = ref.watch(exerciseMapProvider);
    final exerciseMap = exerciseMapAsync.valueOrNull ?? {};

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title ?? 'トレーニング',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    DateFormat('yyyy/MM/dd(E)', 'ja').format(session.date),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (session.durationMinutes != null)
                    Text('${session.durationMinutes}分'),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: setsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('エラー: $e')),
                data: (sets) {
                  // exerciseId でグループ化
                  final grouped = <String, List<WorkoutSet>>{};
                  for (final s in sets) {
                    grouped.putIfAbsent(s.exerciseId, () => []).add(s);
                  }

                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final entry in grouped.entries) ...[
                        Text(
                          exerciseMap[entry.key]?.name ?? entry.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        for (final s in entry.value)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 8, bottom: 2),
                            child: Text(
                              'Set ${s.setNumber}: ${s.weightKg}kg × ${s.reps}回'
                              '${s.isCompleted ? ' ✓' : ''}',
                              style: TextStyle(
                                color: s.isCompleted
                                    ? Colors.green
                                    : null,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---- 種目の進捗タブ ----

class _ExerciseProgressTab extends ConsumerStatefulWidget {
  const _ExerciseProgressTab();

  @override
  ConsumerState<_ExerciseProgressTab> createState() =>
      _ExerciseProgressTabState();
}

class _ExerciseProgressTabState extends ConsumerState<_ExerciseProgressTab> {
  String? _selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseNotifierProvider);

    return exercisesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('エラー: $e')),
      data: (exercises) {
        if (exercises.isEmpty) {
          return const Center(child: Text('種目データがありません'));
        }

        _selectedExerciseId ??= exercises.first.id;

        final progressAsync = ref
            .watch(exerciseProgressProvider(_selectedExerciseId!));

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedExerciseId,
                decoration: const InputDecoration(
                  labelText: '種目を選択',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: exercises
                    .map((e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.name),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedExerciseId = v),
              ),
              const SizedBox(height: 24),
              Text('最高重量の推移',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              progressAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SizedBox(
                  height: 200,
                  child: Center(child: Text('エラー: $e')),
                ),
                data: (progressList) {
                  if (progressList.isEmpty) {
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          'この種目の記録がまだありません',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  final spots = progressList
                      .asMap()
                      .entries
                      .map((e) => FlSpot(
                          e.key.toDouble(), e.value.maxWeight))
                      .toList();

                  final dates = progressList
                      .map((p) => DateFormat('M/d').format(p.date))
                      .toList();

                  return SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              getTitlesWidget: (v, _) => Text(
                                '${v.toInt()}kg',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                return i >= 0 && i < dates.length
                                    ? Text(dates[i],
                                        style: const TextStyle(
                                            fontSize: 10))
                                    : const SizedBox();
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: const Color(0xFF1E88E5),
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: const Color(0xFF1E88E5)
                                  .withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
