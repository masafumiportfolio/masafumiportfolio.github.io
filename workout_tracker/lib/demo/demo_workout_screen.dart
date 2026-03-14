import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'add_exercise_sheet_demo.dart';

class DemoWorkoutScreen extends StatefulWidget {
  final DateTime date;
  const DemoWorkoutScreen({super.key, required this.date});

  @override
  State<DemoWorkoutScreen> createState() => _DemoWorkoutScreenState();
}

class _DemoWorkoutScreenState extends State<DemoWorkoutScreen> {
  final Map<String, List<_SetData>> _exercises = {};
  final Map<String, String> _exerciseNames = {};

  void _addExercise(String id, String name) {
    setState(() {
      _exerciseNames[id] = name;
      _exercises[id] = [_SetData()];
    });
  }

  void _addSet(String id) {
    setState(() => _exercises[id]!.add(_SetData()));
  }

  void _removeSet(String id, int index) {
    setState(() {
      _exercises[id]!.removeAt(index);
      if (_exercises[id]!.isEmpty) {
        _exercises.remove(id);
        _exerciseNames.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('M月d日(E)', 'ja').format(widget.date)),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('保存しました！（デモ版）')),
              );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
      body: _exercises.isEmpty
          ? _EmptyState(onAdd: _showSheet)
          : _ExerciseList(
              exercises: _exercises,
              exerciseNames: _exerciseNames,
              onAddSet: _addSet,
              onRemoveSet: _removeSet,
              onAddExercise: _showSheet,
            ),
    );
  }

  void _showSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DemoAddExerciseSheet(onSelected: _addExercise),
    );
  }
}

class _SetData {
  final weightCtrl = TextEditingController();
  final repsCtrl = TextEditingController();
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('種目を追加してトレーニングを開始しましょう'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
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
        for (final id in exercises.keys) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exerciseNames[id] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Row(children: [
                    SizedBox(width: 36, child: Text('SET', style: TextStyle(fontSize: 12))),
                    SizedBox(width: 8),
                    Expanded(child: Text('重量 (kg)', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))),
                    SizedBox(width: 8),
                    Expanded(child: Text('回数', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))),
                    SizedBox(width: 36),
                  ]),
                  const Divider(),
                  for (int i = 0; i < exercises[id]!.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        SizedBox(
                          width: 36,
                          child: Text('${i + 1}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: exercises[id]![i].weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              hintText: '0',
                              suffixText: 'kg',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: exercises[id]![i].repsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '0',
                              suffixText: '回',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => onRemoveSet(id, i),
                          color: Colors.grey,
                        ),
                      ]),
                    ),
                  TextButton.icon(
                    onPressed: () => onAddSet(id),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('セット追加'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: onAddExercise,
          icon: const Icon(Icons.add),
          label: const Text('種目を追加'),
        ),
      ],
    );
  }
}
