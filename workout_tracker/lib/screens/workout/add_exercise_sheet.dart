import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_database.dart';
import '../../providers/exercise_provider.dart';

class AddExerciseSheet extends ConsumerStatefulWidget {
  final Function(String id, String name) onExerciseSelected;

  const AddExerciseSheet({super.key, required this.onExerciseSelected});

  @override
  ConsumerState<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<AddExerciseSheet> {
  String _searchQuery = '';
  String _selectedCategory = '胸';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Exercise> _filterExercises(List<Exercise> all) {
    if (_searchQuery.isNotEmpty) {
      return all
          .where((e) => e.name.contains(_searchQuery))
          .toList();
    }
    return all.where((e) => e.category == _selectedCategory).toList();
  }

  void _showAddCustomExerciseDialog() {
    final nameController = TextEditingController();
    String selectedCategory = _selectedCategory;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('カスタム種目を追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '種目名',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'カテゴリ',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: kDefaultExercises.keys
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedCategory = v ?? selectedCategory),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                await ref.read(exerciseNotifierProvider.notifier).addCustomExercise(
                      name: name,
                      category: selectedCategory,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exerciseNotifierProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
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
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('種目を選択',
                            style: Theme.of(context).textTheme.titleLarge),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'カスタム種目を追加',
                        onPressed: _showAddCustomExerciseDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '種目名を検索...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ],
              ),
            ),
            if (_searchQuery.isEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...kDefaultExercises.keys.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('カスタム'),
                        selected: _selectedCategory == 'カスタム',
                        onSelected: (_) =>
                            setState(() => _selectedCategory = 'カスタム'),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: exercisesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('エラー: $e')),
                data: (exercises) {
                  List<Exercise> filtered;
                  if (_selectedCategory == 'カスタム' && _searchQuery.isEmpty) {
                    filtered = exercises.where((e) => e.isCustom).toList();
                  } else {
                    filtered = _filterExercises(exercises);
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('種目が見つかりません'),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _showAddCustomExerciseDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('カスタム種目を追加'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      return ListTile(
                        title: Text(exercise.name),
                        subtitle: exercise.isCustom
                            ? const Text('カスタム',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.blue))
                            : null,
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () {
                          widget.onExerciseSelected(
                              exercise.id, exercise.name);
                          Navigator.pop(context);
                        },
                      );
                    },
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
