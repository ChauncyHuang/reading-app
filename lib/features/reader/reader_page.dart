import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'reader_settings.dart';
import 'reader_provider.dart';
import 'text_paginator.dart';

class ReaderPage extends ConsumerStatefulWidget {
  final String bookId;
  final int initialChapterIndex;

  const ReaderPage({
    super.key,
    required this.bookId,
    this.initialChapterIndex = 0,
  });

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  late PageController _pageController;
  TextPaginator? _paginator;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(readerSettingsProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: settings.bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Content area
            GestureDetector(
              onTapUp: (details) {
                final screenWidth = size.width;
                if (details.localPosition.dx < screenWidth / 3) {
                  _previousPage();
                } else if (details.localPosition.dx > screenWidth * 2 / 3) {
                  _nextPage();
                } else {
                  // Center tap — toggle UI
                  ref.read(readerSettingsProvider.notifier).update((s) => s);
                }
              },
              child: _buildPageContent(context, settings, size),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(bookId: widget.bookId),
            ),

            // Bottom progress
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomBar(bookId: widget.bookId),
            ),

            // Settings panel (shown on center tap)
            // TODO: animate in/out
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(BuildContext context, ReaderSettings settings, Size size) {
    if (_paginator == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final pages = _paginator!.pages;
    if (pages.isEmpty) {
      return const Center(child: Text('Empty chapter'));
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: pages.length,
      scrollDirection: Axis.horizontal,
      physics: settings.pageTurnMode == PageTurnMode.scroll
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(
            left: settings.marginLeft,
            right: settings.marginRight,
            top: 40,
            bottom: 40,
          ),
          child: Text(
            pages[index],
            style: settings.textStyle,
            textAlign: TextAlign.justify,
          ),
        );
      },
    );
  }

  void _nextPage() {
    if (_pageController.page != null) {
      final current = _pageController.page!.round();
      if (current < (_paginator?.pageCount ?? 0) - 1) {
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  void _previousPage() {
    if (_pageController.page != null) {
      final current = _pageController.page!.round();
      if (current > 0) {
        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }
}

class _TopBar extends StatelessWidget {
  final String bookId;
  const _TopBar({required this.bookId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.black.withAlpha(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.pop();
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.headphones),
            onPressed: () {
              context.push('/tts');
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () {
              // show settings
            },
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  final String bookId;
  const _BottomBar({required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.black.withAlpha(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('时间', style: Theme.of(context).textTheme.bodySmall),
          Text('进度', style: Theme.of(context).textTheme.bodySmall),
          Text('电量', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
