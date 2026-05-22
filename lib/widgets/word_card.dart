import 'package:flutter/material.dart';
import '../models.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const WordCard({
    super.key,
    required this.word,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          word.word,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          word.translation,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _masteryIcon(word.masteryLevel),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _masteryIcon(int level) {
    if (level == 0) return const SizedBox.shrink();
    return Row(
      children: List.generate(level, (_) => const Icon(Icons.star, size: 14, color: Colors.amber)),
    );
  }
}
