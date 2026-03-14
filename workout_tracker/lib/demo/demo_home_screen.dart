import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'mock_data.dart';
import '../screens/workout/workout_screen.dart';
import 'demo_history_screen.dart';

class DemoHomeScreen extends ConsumerStatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  ConsumerState<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends ConsumerState<DemoHomeScreen> {
  int _currentIndex = 0;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      const DemoHistoryScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '履歴',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutScreen(date: _selectedDay),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('トレーニング開始'),
            )
          : null,
    );
  }

  Widget _buildDashboard() {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('筋トレ記録'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('デモ版'),
                backgroundColor: Colors.orange.withOpacity(0.2),
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _WeeklyStatsCard(),
              const SizedBox(height: 16),
              _buildCalendar(),
              const SizedBox(height: 16),
              _RecentSessionsList(),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Card(
      child: TableCalendar(
        firstDay: DateTime.utc(2026, 1, 1),
        lastDay: DateTime.utc(2026, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        eventLoader: (day) {
          return mockTrainingDays.any((d) =>
                  d.year == day.year &&
                  d.month == day.month &&
                  d.day == day.day)
              ? ['workout']
              : [];
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isNotEmpty) {
              return Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E88E5),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF1E88E5),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(formatButtonVisible: false),
        locale: 'ja_JP',
      ),
    );
  }
}

class _WeeklyStatsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今週のトレーニング',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                    label: '回数',
                    value: '${mockWeeklyStats['sessions']}',
                    unit: '回'),
                _StatItem(
                    label: '合計セット',
                    value: '${mockWeeklyStats['totalSets']}',
                    unit: 'set'),
                _StatItem(
                    label: '連続記録',
                    value: '${mockWeeklyStats['streak']}',
                    unit: '日🔥'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _StatItem(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold, color: const Color(0xFF1E88E5))),
        Text('$label ($unit)',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RecentSessionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('最近のトレーニング',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final session in mockSessions.take(3))
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1E88E5),
                child: Text(
                  '${session.durationMinutes}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(session.title),
              subtitle: Text(
                DateFormat('M月d日(E)', 'ja').format(session.date) +
                    '  ${session.exercises.fold(0, (sum, e) => sum + e.sets.length)}セット',
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }
}
