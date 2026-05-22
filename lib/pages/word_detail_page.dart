import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../word_provider.dart';
import '../db_helper.dart';
import '../tts_service.dart';

class WordDetailPage extends StatefulWidget {
  final String wordId;
  const WordDetailPage({super.key, required this.wordId});

  @override
  State<WordDetailPage> createState() => _WordDetailPageState();
}

class _WordDetailPageState extends State<WordDetailPage> {
  Word? _word;
  bool _loading = true;
  bool _editing = false;

  final _wordController = TextEditingController();
  final _translationController = TextEditingController();
  final _pronunciationController = TextEditingController();
  final _partOfSpeechController = TextEditingController();
  final _exampleSentController = TextEditingController();
  final _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _tts.init();
    _loadWord();
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

  Future<void> _loadWord() async {
    final word = await DbHelper.getWordById(widget.wordId);
    if (mounted) {
      setState(() {
        _word = word;
        _loading = false;
        if (word != null) {
          _wordController.text = word.word;
          _translationController.text = word.translation;
          _pronunciationController.text = word.pronunciation ?? '';
          _partOfSpeechController.text = word.partOfSpeech ?? '';
          _exampleSentController.text = word.exampleSent ?? '';
        }
      });
    }
  }

  Future<void> _saveEdit() async {
    if (_word == null) return;
    final updated = _word!.copyWith(
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
    await context.read<WordProvider>().updateWord(updated);
    if (mounted) {
      setState(() {
        _word = updated;
        _editing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('单词详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_word == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('单词详情')),
        body: const Center(child: Text('未找到该单词')),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('单词详情'),
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _editing = !_editing),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 单词
            if (_editing) ...[
              _buildField('单词', _wordController),
              const SizedBox(height: 12),
              _buildField('音标', _pronunciationController),
              Row(
                children: [
                  const Icon(Icons.volume_up, color: Colors.indigo),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('试听发音'),
                    onPressed: () => _tts.speak(_wordController.text.trim()),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildField('翻译', _translationController, maxLines: 2),
              const SizedBox(height: 12),
              _buildField('词性', _partOfSpeechController),
              const SizedBox(height: 12),
              _buildField('例句', _exampleSentController, maxLines: 2),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saveEdit,
                icon: const Icon(Icons.save),
                label: const Text('保存修改'),
              ),
            ] else ...[
              // 查看模式
              Center(
                child: Column(
                  children: [
                    Text(
                      _word!.word,
                      style:
                          theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (_word!.pronunciation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _word!.pronunciation!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill,
                          color: Colors.indigo, size: 48),
                      onPressed: () => _tts.speak(_word!.word),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _infoRow('翻译', _word!.translation),
              if (_word!.partOfSpeech != null)
                _infoRow('词性', _word!.partOfSpeech!),
              if (_word!.exampleSent != null)
                _infoRow('例句', _word!.exampleSent!),
              const SizedBox(height: 16),
              _infoRow('掌握度', '⭐' * _word!.masteryLevel),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
          {int maxLines = 1}) =>
      TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        maxLines: maxLines,
      );

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              child: Text(label,
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
