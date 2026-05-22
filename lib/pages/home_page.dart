import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth_provider.dart';
import '../word_provider.dart';
import '../sync_service.dart';
import '../widgets/word_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordProvider>().loadWords();
      _autoSync();
    });
  }

  Future<void> _autoSync() async {
    if (!context.read<AuthProvider>().isLoggedIn) return;
    await _doSync();
  }

  Future<void> _doSync() async {
    setState(() => _syncing = true);
    final result = await SyncService.sync();
    setState(() => _syncing = false);

    if (result.ok) {
      if (result.pulled > 0 || result.pushed > 0) {
        if (mounted) context.read<WordProvider>().loadWords();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.pulled == 0 && result.pushed == 0
                ? '已是最新'
                : '同步完成: 拉取 ${result.pulled} 条, 推送 ${result.pushed} 条'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步失败: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WordProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的词库'),
        actions: [
          if (auth.isLoggedIn)
            _syncing
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton(
                    icon: const Icon(Icons.sync),
                    tooltip: '同步',
                    onPressed: _doSync,
                  )
          else
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: '登录同步',
              onPressed: () => context.push('/login'),
            ),
          IconButton(
            icon: const Icon(Icons.fitness_center),
            tooltip: '开始背诵',
            onPressed: () => context.push('/review'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.words.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('还没有单词，点击下方按钮添加',
                          style: TextStyle(color: Colors.grey.shade600)),
                      if (!auth.isLoggedIn)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.cloud_sync),
                            label: const Text('登录后跨设备同步'),
                            onPressed: () => context.push('/login'),
                          ),
                        ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await provider.loadWords();
                    if (auth.isLoggedIn) await _doSync();
                  },
                  child: ListView.builder(
                    itemCount: provider.words.length,
                    itemBuilder: (context, index) {
                      final word = provider.words[index];
                      return WordCard(
                        word: word,
                        onTap: () => context.push('/word/${word.id}'),
                        onDelete: () => _confirmDelete(word.id),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-word'),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('要删除这个单词吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<WordProvider>().deleteWord(id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
