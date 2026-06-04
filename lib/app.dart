import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'shared/theme/app_theme.dart';
import 'features/bookshelf/bookshelf_page.dart';
import 'features/search/search_page.dart';
import 'features/discovery/discovery_page.dart';
import 'features/settings/settings_page.dart';
import 'features/reader/reader_page.dart';
import 'features/book_detail/book_detail_page.dart';
import 'features/source_manage/source_manage_page.dart';
import 'features/source_manage/source_import_page.dart';
import 'features/tts/tts_control_panel.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/bookshelf',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/bookshelf',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BookshelfPage(),
            ),
          ),
          GoRoute(
            path: '/discovery',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscoveryPage(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchPage(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/reader',
        builder: (context, state) {
          final bookId = state.uri.queryParameters['bookId'] ?? '';
          final chapterIndex = int.tryParse(state.uri.queryParameters['chapterIndex'] ?? '0') ?? 0;
          return ReaderPage(bookId: bookId, initialChapterIndex: chapterIndex);
        },
      ),
      GoRoute(
        path: '/book-detail',
        builder: (context, state) {
          final bookId = state.uri.queryParameters['bookId'] ?? '';
          return BookDetailPage(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/source-manage',
        builder: (context, state) => const SourceManagePage(),
      ),
      GoRoute(
        path: '/source-import',
        builder: (context, state) => const SourceImportPage(),
      ),
      GoRoute(
        path: '/tts',
        builder: (context, state) {
          final text = state.uri.queryParameters['text'] ?? '';
          return TtsControlPanel(text: text);
        },
      ),
    ],
  );
});

class ReadingApp extends ConsumerWidget {
  const ReadingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'Reading',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onNavigationChanged(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        context.go('/bookshelf');
        break;
      case 1:
        context.go('/discovery');
        break;
      case 2:
        context.go('/search');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavigationChanged,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books), label: '书架'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: '发现'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: '搜索'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
