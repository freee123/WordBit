import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models.dart';
import '../word_provider.dart';
import '../db_helper.dart';
import '../translation_service.dart';
import '../tts_service.dart';

class AddWordPage extends StatefulWidget {
  const AddWordPage({super.key});

  @override
  State<AddWordPage> createState() => _AddWordPageState();
}

class _AddWordPageState extends State<AddWordPage> {
  final _wordController = TextEditingController();
  final _translationController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _partOfSpeechController = TextEditingController();
  final _exampleSentController = TextEditingController();
  final _tts = TtsService();

  bool _loading = false;
  bool _translated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tts.init();
  }

  @override
  void dispose() {
    _wordController.dispose();
    _translationController.dispose();
    _pronunciationController.dispose();
    _partOfSpeechController.dispose();
    _exampleSentController.dispose();
    _tts.dispose();
    super.dispose();
  }

  Future<void> _fetchTranslation() async {
    final text = _wordController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = '请输入单词');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 先查本地词库
      final existing = await DbHelper.getWordByText(text);
      if (existing != null) {
        setState(() {
          _loading = false;
          _error = '该单词已在词库中';
        });
        return;
      }

      final result = await TranslationService.translate(text);

      _translationController.text = result.translation;
      _pronunciationController.text = result.pronunciation ?? '';
      _partOfSpeechController.text = result.partOfSpeech ?? '';
      _exampleSentController.text = result.exampleSent ?? '';

      setState(() {
        _loading = false;
        _translated = true;
      });

      // 拼写校验
      if (!result.spellOk && mounted) {
        _warnSpellError(text);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _warnSpellError(String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('拼写提醒'),
        content: Text('未在词典中找到「$text」，可能是拼写错误。\n\n仍要添加吗？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _wordController.clear();
                _translated = false;
              });
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('仍添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_wordController.text.trim().isEmpty) return;
    if (_translationController.text.trim().isEmpty) return;

    final word = Word(
      word: _wordController.text.trim(),
      translation: _translationController.text.trim(),
      pronunciation: _pronunciationController.text.trim().isEmpty
          ? null
          : _pronunciationController.text.trim(),
      partOfSpeech: _partOfSpeechController.text.trim().isEmpty
          ? null
          : _partOfSpeechController.text.trim(),
      exampleSent: _exampleSentController.text.trim().isEmpty
          ? null
          : _exampleSentController.text.trim(),
    );

    if (mounted) {
      context.read<WordProvider>().addWord(word);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加单词'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: '批量添加',
            onPressed: () => context.push('/batch-add'),
          ),
          if (_translated)
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('保存'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 单词输入行
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wordController,
                    decoration: const InputDecoration(
                      labelText: '输入英文单词',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.none,
                    onSubmitted: (_) => _fetchTranslation(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _fetchTranslation,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate),
                  label: const Text('自动补全'),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
              ),
            ],

            if (_translated) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),

              // 发音行
              Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _pronunciationController,
                      decoration: const InputDecoration(
                        labelText: '音标',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill,
                        color: Colors.indigo, size: 32),
                    onPressed: () => _tts.speak(_wordController.text.trim()),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 翻译
              TextField(
                controller: _translationController,
                decoration: const InputDecoration(
                  labelText: '中文翻译',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 12),

              // 词性
              TextField(
                controller: _partOfSpeechController,
                decoration: const InputDecoration(
                  labelText: '词性 (n./v./adj.)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),

              const SizedBox(height: 12),

              // 例句
              TextField(
                controller: _exampleSentController,
                decoration: const InputDecoration(
                  labelText: '例句',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('保存到词库'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
