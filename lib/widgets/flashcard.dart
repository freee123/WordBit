import 'package:flutter/material.dart';
import '../models.dart';
import '../tts_service.dart';

class Flashcard extends StatefulWidget {
  final Word word;
  final VoidCallback? onReveal;

  const Flashcard({
    super.key,
    required this.word,
    this.onReveal,
  });

  @override
  State<Flashcard> createState() => _FlashcardState();
}

class _FlashcardState extends State<Flashcard> {
  bool _revealed = false;
  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _tts.init();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  void _reveal() {
    if (_revealed) return;
    setState(() => _revealed = true);
    _tts.speak(widget.word.word);
    widget.onReveal?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _reveal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            // 英文单词
            Text(
              widget.word.word,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 喇叭
            IconButton(
              icon: const Icon(Icons.volume_up, size: 36),
              onPressed: () => _tts.speak(widget.word.word),
            ),

            const SizedBox(height: 16),

            // 中文释义（点击后显示）
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _revealed
                  ? Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 12),
                        if (widget.word.pronunciation != null) ...[
                          Text(
                            widget.word.pronunciation!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          widget.word.translation,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.word.partOfSpeech != null) ...[
                          const SizedBox(height: 12),
                          Chip(label: Text(widget.word.partOfSpeech!)),
                        ],
                        if (widget.word.exampleSent != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            widget.word.exampleSent!,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    )
                  : Text(
                      '点击显示释义',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
