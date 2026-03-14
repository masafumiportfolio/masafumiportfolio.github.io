import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

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
        children: [
          _WorkoutHistoryTab(),
          _ExerciseProgressTab(),
        ],
      ),
    );
  }
}

class _WorkoutHistoryTab extends StatelessWidget {
  // TODO: Riverpodプロバイダーから実際のデータを取得
  final _sampleSessions = const [
    {'date': '2026/03/13', 'title': '胸・三頭筋', 'sets': 18, 'duration': 60},
    {'date': '2026/03/11', 'title': '背中・二頭筋', 'sets': 20, 'duration': 70},
    {'date': '2026/03/09', 'title': '脚の日', 'sets': 15, 'duration': 55},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sampleSessions.length,
      itemBuilder: (context, index) {
        final session = _sampleSessions[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1E88E5),
              child: Text(
                '${session['duration']}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(session['title'] as String),
            subtitle: Text('${session['date']}  ${session['sets']}セット'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: セッション詳細画面へ
            },
          ),
        );
      },
    );
  }
}

class _ExerciseProgressTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: 'ベンチプレス',
            decoration: const InputDecoration(
              labelText: '種目を選択',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: ['ベンチプレス', 'スクワット', 'デッドリフト']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (_) {},
          ),
          const SizedBox(height: 24),
          Text('最高重量の推移',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const dates = ['3/1', '3/5', '3/9', '3/13'];
                        final i = value.toInt();
                        return i >= 0 && i < dates.length
                            ? Text(dates[i], style: const TextStyle(fontSize: 10))
                            : const SizedBox();
                      },
                    ),
                  ),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 60),
                      FlSpot(1, 62.5),
                      FlSpot(2, 62.5),
                      FlSpot(3, 65),
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
        ],
      ),
    );
  }
}
