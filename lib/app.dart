import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pages/home_page.dart';
import 'pages/add_word_page.dart';
import 'pages/word_detail_page.dart';
import 'pages/review_page.dart';
import 'pages/login_page.dart';
import 'pages/batch_add_page.dart';
import 'pages/settings_page.dart';

class MemoryWordsApp extends StatelessWidget {
  const MemoryWordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '背单词',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: HomePage(),
      ),
    ),
    GoRoute(
      path: '/add-word',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: AddWordPage(),
      ),
    ),
    GoRoute(
      path: '/word/:id',
      pageBuilder: (context, state) => NoTransitionPage(
        child: WordDetailPage(wordId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/review',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ReviewPage(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LoginPage(),
      ),
    ),
    GoRoute(
      path: '/batch-add',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: BatchAddPage(),
      ),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SettingsPage(),
      ),
    ),
  ],
);
