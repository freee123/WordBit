import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../review_provider.dart';
import '../widgets/flashcard.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().loadReviewQueue();
    });
  }

  void _onReveal() {
    setState(() => _revealed = true);
  }

  Future<void> _rateWord(int result) async {
    await context.read<ReviewProvider>().rateWord(result);
    setState(() => _revealed = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: provider.total > 0
            ? Text('${provider.currentIndex + 1} / ${provider.total}')
            : const Text('背诵复习'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(provider, theme),
    );
  }

  Widget _buildBody(ReviewProvider provider, ThemeData theme) {
    // 加载完成且无内容
    if (provider.total == 0 && !provider.finished) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green.shade400),
            const SizedBox(height: 16),
            Text('所有单词都已复习完毕',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('新增单词后会出现在这里',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    // 全部完成
    if (provider.finished) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events,
                  size: 64, color: Colors.amber.shade600),
              const SizedBox(height: 16),
              Text('本轮复习完成!', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 24),
              _statCard('记得', '${provider.correctCount}', Colors.green),
              const SizedBox(height: 8),
              _statCard('模糊', '${provider.fuzzyCount}', Colors.orange),
              const SizedBox(height: 8),
              _statCard('忘记', '${provider.forgotCount}', Colors.red),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => provider.loadReviewQueue(),
                icon: const Icon(Icons.refresh),
                label: const Text('再来一轮'),
              ),
            ],
          ),
        ),
      );
    }

    // 背诵中
    final word = provider.currentWord!;
    return Column(
      children: [
        LinearProgressIndicator(
          value: (provider.currentIndex) / provider.total,
        ),
        const SizedBox(height: 24),

        // 闪卡
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Flashcard(
            key: ValueKey(word.id),
            word: word,
            onReveal: _onReveal,
          ),
        ),

        const SizedBox(height: 32),

        // 评分按钮（点击显示释义后才出现）
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _revealed ? 1.0 : 0.0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: _revealed ? Offset.zero : const Offset(0, 0.2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _rateButton(
                      label: '忘记',
                      color: Colors.red,
                      onTap: () => _rateWord(0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _rateButton(
                      label: '模糊',
                      color: Colors.orange,
                      onTap: () => _rateWord(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _rateButton(
                      label: '记得',
                      color: Colors.green,
                      onTap: () => _rateWord(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          '剩余 ${provider.remaining} 个',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _statCard(String label, String count, Color color) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: color, fontSize: 18)),
            Text(count,
                style: TextStyle(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _rateButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}
