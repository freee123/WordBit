import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../db_helper.dart';
import '../word_provider.dart';
import '../translation_service.dart';

class BatchAddPage extends StatefulWidget {
  const BatchAddPage({super.key});

  @override
  State<BatchAddPage> createState() => _BatchAddPageState();
}

class _BatchAddPageState extends State<BatchAddPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _resultMsg;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addAll() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    // 按换行、逗号、空格分割
    final words = raw
        .split(RegExp(r'[\n,，\s]+'))
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty && RegExp(r'^[a-z]+$').hasMatch(s))
        .toSet()
        .toList();

    if (words.isEmpty) {
      setState(() => _resultMsg = '未检测到有效单词');
      return;
    }

    // 确认对话框
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认批量添加'),
        content: Text('共检测到 ${words.length} 个单词:\n\n${words.join('、')}\n\n确认添加？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认添加'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() {
      _loading = true;
      _resultMsg = null;
    });

    int added = 0;
    int duplicate = 0;
    int failed = 0;

    for (final word in words) {
      try {
        // 查重
        final exist = await DbHelper.getWordByText(word);
        if (exist != null) {
          duplicate++;
          continue;
        }

        final result = await TranslationService.translate(word);
        if (result.translation.isEmpty || result.translation.contains('错误')) {
          failed++;
          continue;
        }

        final w = Word(
          word: word,
          translation: result.translation,
          pronunciation: result.pronunciation,
          partOfSpeech: result.partOfSpeech,
          exampleSent: result.exampleSent,
        );

        if (mounted) {
          context.read<WordProvider>().addWord(w);
        }
        added++;
      } catch (_) {
        failed++;
      }
    }

    setState(() {
      _loading = false;
      final parts = <String>[];
      if (added > 0) parts.add('成功添加 $added 个');
      if (duplicate > 0) parts.add('$duplicate 个已存在');
      if (failed > 0) parts.add('$failed 个添加失败');
      _resultMsg = parts.join('，');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('批量添加'),
        actions: [
          TextButton.icon(
            onPressed: _loading ? null : _addAll,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('确认添加'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '输入多个单词，每行一个，或用逗号分隔',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  hintText: 'hello\nworld\napple',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (_resultMsg != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_resultMsg!,
                    style: TextStyle(color: Colors.green.shade700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
