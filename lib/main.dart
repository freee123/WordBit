import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'api_client.dart';
import 'auth_provider.dart';
import 'word_provider.dart';
import 'review_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows/Linux 桌面端需要 FFI 初始化 sqflite
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await ApiClient.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WordProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: const MemoryWordsApp(),
    ),
  );
}
