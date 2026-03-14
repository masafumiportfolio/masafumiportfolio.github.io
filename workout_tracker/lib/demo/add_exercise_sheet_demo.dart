import 'package:flutter/material.dart';

const _defaultExercises = {
  '胸': ['ベンチプレス', 'インクラインベンチプレス', 'ダンベルフライ', 'チェストプレス', 'ディップス'],
  '背中': ['デッドリフト', 'ラットプルダウン', '懸垂', 'ベントオーバーロウ', 'シーテッドロウ'],
  '脚': ['スクワット', 'レッグプレス', 'レッグカール', 'レッグエクステンション', 'カーフレイズ'],
  '肩': ['ショルダープレス', 'サイドレイズ', 'フロントレイズ', 'リアレイズ', 'フェイスプル'],
  '腕': ['バーベルカール', 'ダンベルカール', 'トライセプスプレスダウン', 'スカルクラッシャー'],
  '腹筋': ['クランチ', 'レッグレイズ', 'プランク', 'ロシアンツイスト', 'アブローラー'],
};

class DemoAddExerciseSheet extends StatefulWidget {
  final Function(String id, String name) onSelected;
  const DemoAddExerciseSheet({super.key, required this.onSelected});

  @override
  State<DemoAddExerciseSheet> createState() => _DemoAddExerciseSheetState();
}

class _DemoAddExerciseSheetState extends State<DemoAddExerciseSheet> {
  String _search = '';
  String _category = '胸';

  List<String> get _filtered {
    if (_search.isNotEmpty) {
      return _defaultExercises.values
          .expand((e) => e)
          .where((e) => e.contains(_search))
          .toList();
    }
    return _defaultExercises[_category] ?? [];
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600], borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text('種目を選択', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: '種目名を検索...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ]),
            ),
            if (_search.isEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _defaultExercises.keys.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: _category == cat,
                      onSelected: (_) => setState(() => _category = cat),
                    ),
                  )).toList(),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final name = _filtered[i];
                  return ListTile(
                    title: Text(name),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () {
                      widget.onSelected(name.hashCode.toString(), name);
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
