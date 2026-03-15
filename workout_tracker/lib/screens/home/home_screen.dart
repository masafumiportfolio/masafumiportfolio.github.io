import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../providers/stats_provider.dart';
import '../../providers/workout_provider.dart';
import '../workout/workout_screen.dart';
import '../history/history_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardTab(
        selectedDay: _selectedDay,
        onDaySelected: (day) => setState(() => _selectedDay = day),
      ),
      const HistoryScreen(),
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
}

class _DashboardTab extends ConsumerWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _DashboardTab({
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('筋トレ記録'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => FirebaseAuth.instance.signOut(),
              tooltip: 'ログアウト',
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _WeeklyStatsCard(),
              const SizedBox(height: 16),
              _CalendarCard(
                selectedDay: selectedDay,
                onDaySelected: onDaySelected,
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

class _WeeklyStatsCard extends ConsumerWidget {
  const _WeeklyStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('今週のトレーニング',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            statsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('エラー: $e',
                  style: const TextStyle(color: Colors.red)),
              data: (stats) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                      label: '回数',
                      value: '${stats.sessionsCount}',
                      unit: '回'),
                  _StatItem(
                      label: '合計セット数',
                      value: '${stats.totalSets}',
                      unit: 'セット'),
                  _StatItem(
                      label: '連続記録',
                      value: '${stats.streakDays}',
                      unit: '日'),
                ],
              ),
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
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E88E5)),
        ),
        Text('$label ($unit)',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CalendarCard extends ConsumerStatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarCard({
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  ConsumerState<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends ConsumerState<_CalendarCard> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final workoutDatesAsync = ref.watch(workoutDatesProvider);
    final workoutDates = workoutDatesAsync.valueOrNull ?? {};

    return Card(
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
        onDaySelected: (selected, focused) {
          setState(() => _focusedDay = focused);
          widget.onDaySelected(selected);
        },
        eventLoader: (day) {
          final dateKey = DateTime(day.year, day.month, day.day);
          return workoutDates.contains(dateKey) ? [true] : [];
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: const Color(0xFF1E88E5).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF1E88E5),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Color(0xFF43A047),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(formatButtonVisible: false),
        locale: 'ja_JP',
      ),
    );
  }
}
