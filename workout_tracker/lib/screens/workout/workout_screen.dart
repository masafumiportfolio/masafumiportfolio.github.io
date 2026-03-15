import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/workout_provider.dart';
import 'add_exercise_sheet.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const WorkoutScreen({super.key, required this.date});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  // exerciseId -> セットリスト
  final Map<String, List<_SetData>> _exercises = {};
  // exerciseId -> 種目名
  final Map<String, String> _exerciseNames = {};

  void _addExercise(String exerciseId, String exerciseName) {
    if (_exercises.containsKey(exerciseId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$exerciseName は既に追加されています')),
      );
      return;
    }
    setState(() {
      _exerciseNames[exerciseId] = exerciseName;
      _exercises[exerciseId] = [_SetData()];
    });
  }

  void _addSet(String exerciseId) {
    setState(() {
      _exercises[exerciseId]!.add(_SetData());
    });
  }

  void _removeSet(String exerciseId, int index) {
    setState(() {
      _exercises[exerciseId]!.removeAt(index);
      if (_exercises[exerciseId]!.isEmpty) {
        _exercises.remove(exerciseId);
        _exerciseNames.remove(exerciseId);
      }
    });
  }

  Future<void> _saveWorkout() async {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('種目を追加してください')),
      );
      return;
    }

    // _SetData を SetRecord に変換
    final exerciseSets = <String, List<SetRecord>>{};
    for (final entry in _exercises.entries) {
      exerciseSets[entry.key] = entry.value.map((s) {
        return (
          weight: double.tryParse(s.weightController.text) ?? 0.0,
          reps: int.tryParse(s.repsController.text) ?? 0,
          isCompleted: s.isCompleted,
        );
      }).toList();
    }

    try {
      await ref.read(workoutNotifierProvider.notifier).saveSession(
            date: widget.date,
            exerciseSets: exerciseSets,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('トレーニングを保存しました！')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final sets in _exercises.values) {
      for (final s in sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(workoutNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('M月d日(E)', 'ja').format(widget.date)),
        actions: [
          TextButton(
            onPressed: isSaving ? null : _saveWorkout,
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: _exercises.isEmpty
          ? _EmptyState(onAddExercise: _showAddExerciseSheet)
          : _ExerciseList(
              exercises: _exercises,
              exerciseNames: _exerciseNames,
              onAddSet: _addSet,
              onRemoveSet: _removeSet,
              onAddExercise: _showAddExerciseSheet,
            ),
    );
  }

  void _showAddExerciseSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddExerciseSheet(
        onExerciseSelected: _addExercise,
      ),
    );
  }
}

class _SetData {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  bool isCompleted = false;

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddExercise;
  const _EmptyState({required this.onAddExercise});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('種目を追加してトレーニングを開始しましょう',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddExercise,
            icon: const Icon(Icons.add),
            label: const Text('種目を追加'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  final Map<String, List<_SetData>> exercises;
  final Map<String, String> exerciseNames;
  final Function(String) onAddSet;
  final Function(String, int) onRemoveSet;
  final VoidCallback onAddExercise;

  const _ExerciseList({
    required this.exercises,
    required this.exerciseNames,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onAddExercise,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final exerciseId in exercises.keys) ...[
          _ExerciseCard(
            exerciseId: exerciseId,
            exerciseName: exerciseNames[exerciseId] ?? '',
            sets: exercises[exerciseId]!,
            onAddSet: () => onAddSet(exerciseId),
            onRemoveSet: (i) => onRemoveSet(exerciseId, i),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: onAddExercise,
          icon: const Icon(Icons.add),
          label: const Text('種目を追加'),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final String exerciseId;
  final String exerciseName;
  final List<_SetData> sets;
  final VoidCallback onAddSet;
  final Function(int) onRemoveSet;

  const _ExerciseCard({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.onAddSet,
    required this.onRemoveSet,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exerciseName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Row(
              children: [
                SizedBox(
                    width: 40,
                    child: Text('SET', textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Expanded(
                    child:
                        Text('重量 (kg)', textAlign: TextAlign.center)),
                SizedBox(width: 8),
                Expanded(
                    child: Text('回数', textAlign: TextAlign.center)),
                SizedBox(width: 40),
              ],
            ),
            const Divider(),
            for (int i = 0; i < sets.length; i++)
              _SetRow(
                setNumber: i + 1,
                data: sets[i],
                onRemove: () => onRemoveSet(i),
              ),
            TextButton.icon(
              onPressed: onAddSet,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('セット追加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int setNumber;
  final _SetData data;
  final VoidCallback onRemove;

  const _SetRow(
      {required this.setNumber, required this.data, required this.onRemove});

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(
                () => widget.data.isCompleted = !widget.data.isCompleted),
            child: Container(
              width: 40,
              alignment: Alignment.center,
              child: widget.data.isCompleted
                  ? const Icon(Icons.check_circle,
                      color: Color(0xFF1E88E5), size: 22)
                  : Text(
                      '${widget.setNumber}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.data.weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: 'kg',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.data.repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: '回',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onRemove,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
