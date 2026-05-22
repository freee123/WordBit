import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = _isLogin
        ? await auth.login(_userCtrl.text.trim(), _passCtrl.text.trim())
        : await auth.register(_userCtrl.text.trim(), _passCtrl.text.trim());
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? '登录' : '注册')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(auth.error!, style: TextStyle(color: Colors.red.shade700)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: auth.loading ? null : _submit,
                child: auth.loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isLogin ? '登录' : '注册'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() => _isLogin = !_isLogin);
                auth.clearError();
              },
              child: Text(_isLogin ? '没有账号？点此注册' : '已有账号？点此登录'),
            ),
          ],
        ),
      ),
    );
  }
}
