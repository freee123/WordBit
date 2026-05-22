import 'package:flutter/material.dart';
import '../api_client.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _urlCtrl = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = ApiClient.baseUrl;
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ApiClient.setBaseUrl(_urlCtrl.text.trim());
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('服务器地址',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                hintText: 'http://localhost:8080',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Android 模拟器: http://10.0.2.2:8080\n真机/PC: http://你的IP:8080',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_saved ? Icons.check : Icons.save),
              label: Text(_saved ? '已保存' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}
