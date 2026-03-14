import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'mock_data.dart';

class DemoHistoryScreen extends StatefulWidget {
  const DemoHistoryScreen({super.key});

  @override
  State<DemoHistoryScreen> createState() => _DemoHistoryScreenState();
}

class _DemoHistoryScreenState extends State<DemoHistoryScreen>
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
        children: [
          _HistoryTab(),
          _ProgressTab(),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockSessions.length,
      itemBuilder: (context, index) {
        final session = mockSessions[index];
        final totalSets =
            session.exercises.fold(0, (sum, e) => sum + e.sets.length);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1E88E5),
              child: Text(
                '${session.durationMinutes}m',
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(session.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              DateFormat('M月d日(E)', 'ja').format(session.date) +
                  '  $totalSets セット',
            ),
            children: [
              for (final exercise in session.exercises)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      for (int i = 0; i < exercise.sets.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 2),
                          child: Text(
                            'Set ${i + 1}: ${exercise.sets[i].weightKg}kg × ${exercise.sets[i].reps}回',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      const Divider(),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressTab extends StatefulWidget {
  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  String _selectedExercise = 'ベンチプレス';

  @override
  Widget build(BuildContext context) {
    final points = mockProgress[_selectedExercise] ?? [];
    final maxWeight = points.isEmpty
        ? 0.0
        : points.map((p) => p.weightKg).reduce((a, b) => a > b ? a : b);
    final minWeight = points.isEmpty
        ? 0.0
        : points.map((p) => p.weightKg).reduce((a, b) => a < b ? a : b);
    final improvement = points.length >= 2
        ? points.last.weightKg - points.first.weightKg
        : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedExercise,
            decoration: const InputDecoration(
              labelText: '種目を選択',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: mockProgress.keys
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _selectedExercise = v!),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                    label: '最高重量',
                    value: '$maxWeight kg',
                    icon: Icons.emoji_events,
                    color: Colors.amber),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                    label: '期間伸び',
                    value: '+$improvement kg',
                    icon: Icons.trending_up,
                    color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('最高重量の推移',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: points.isEmpty
                ? const Center(child: Text('データがありません'))
                : LineChart(
                    LineChartData(
                      minY: minWeight - 5,
                      maxY: maxWeight + 5,
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}kg',
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
                              if (i < 0 || i >= points.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormat('M/d').format(points[i].date),
                                  style: const TextStyle(fontSize: 9),
                                ),
                              );
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
                          spots: [
                            for (int i = 0; i < points.length; i++)
                              FlSpot(i.toDouble(), points[i].weightKg),
                          ],
                          isCurved: true,
                          color: const Color(0xFF1E88E5),
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF1E88E5).withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Text('記録一覧', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final p in points.reversed)
            ListTile(
              dense: true,
              leading: const Icon(Icons.fitness_center, size: 18),
              title: Text('${p.weightKg} kg'),
              trailing: Text(DateFormat('M月d日', 'ja').format(p.date),
                  style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
