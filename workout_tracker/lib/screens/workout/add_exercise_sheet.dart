import 'package:flutter/material.dart';

/// デフォルト種目マスタ
const _defaultExercises = {
  '胸': ['ベンチプレス', 'インクラインベンチプレス', 'ダンベルフライ', 'チェストプレス', 'ディップス'],
  '背中': ['デッドリフト', 'ラットプルダウン', '懸垂', 'ベントオーバーロウ', 'シーテッドロウ'],
  '脚': ['スクワット', 'レッグプレス', 'レッグカール', 'レッグエクステンション', 'カーフレイズ'],
  '肩': ['ショルダープレス', 'サイドレイズ', 'フロントレイズ', 'リアレイズ', 'フェイスプル'],
  '腕': ['バーベルカール', 'ダンベルカール', 'トライセプスプレスダウン', 'スカルクラッシャー'],
  '腹筋': ['クランチ', 'レッグレイズ', 'プランク', 'ロシアンツイスト', 'アブローラー'],
};

class AddExerciseSheet extends StatefulWidget {
  final Function(String id, String name) onExerciseSelected;

  const AddExerciseSheet({super.key, required this.onExerciseSelected});

  @override
  State<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<AddExerciseSheet> {
  String _searchQuery = '';
  String _selectedCategory = '胸';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredExercises {
    if (_searchQuery.isNotEmpty) {
      return _defaultExercises.values
          .expand((e) => e)
          .where((e) => e.contains(_searchQuery))
          .toList();
    }
    return _defaultExercises[_selectedCategory] ?? [];
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('種目を選択',
                      style: Theme.of(context).textTheme.titleLarge),
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
                  children: _defaultExercises.keys.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filteredExercises.length,
                itemBuilder: (context, index) {
                  final name = _filteredExercises[index];
                  return ListTile(
                    title: Text(name),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () {
                      widget.onExerciseSelected(
                          name.hashCode.toString(), name);
                      Navigator.pop(context);
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
