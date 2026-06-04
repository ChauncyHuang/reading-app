import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/database/database.dart';
import '../../core/rule_engine/rule_engine.dart';
import 'book_detail_provider.dart';

class BookDetailPage extends ConsumerStatefulWidget {
  final String bookId;
  const BookDetailPage({super.key, required this.bookId});

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  static const _uuid = Uuid();
  bool _isNewBook = false;
  String _newName = '';
  String _newAuthor = '';
  String _newSource = '';
  String _newDetailUrl = '';
  String _newCoverUrl = '';
  String? _tocUrl;

  @override
  void initState() {
    super.initState();
    // Parse new book params from query if bookId is 'new'
    if (widget.bookId == 'new') {
      _isNewBook = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNewBookParams();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBookInfo();
      });
    }
  }

  Future<void> _loadNewBookParams() async {
    // Actually read from GoRouter state
  }

  Future<void> _loadBookInfo() async {
    // Fetch book info and chapter list from source
  }

  @override
  Widget build(BuildContext context) {
    if (_isNewBook) return _buildNewBookView();

    final detailAsync = ref.watch(bookDetailProvider(widget.bookId));

    return Scaffold(
      appBar: AppBar(title: const Text('书籍详情')),
      body: detailAsync.when(
        data: (state) {
          if (state.book == null) return const Center(child: Text('书籍不存在'));
          return _BookDetailContent(
            book: state.book!,
            chapters: state.chapters,
            bookId: widget.bookId,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildNewBookView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('正在获取书籍信息...'),
        ],
      ),
    );
  }
}

class _BookDetailContent extends ConsumerWidget {
  final Book book;
  final List<Chapter> chapters;
  final String bookId;

  const _BookDetailContent({
    required this.book,
    required this.chapters,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Book header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.coverUrl != null
                  ? CachedNetworkImage(imageUrl: book.coverUrl!, width: 100, height: 140, fit: BoxFit.cover)
                  : Container(
                      width: 100,
                      height: 140,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(book.name[0], style: TextStyle(fontSize: 40, color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('作者: ${book.author}', style: Theme.of(context).textTheme.bodyMedium),
                  if (book.kind != null) ...[
                    const SizedBox(height: 2),
                    Text('分类: ${book.kind}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                  if (book.wordCount != null) ...[
                    const SizedBox(height: 2),
                    Text('字数: ${book.wordCount}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 4),
                  Text('来源: ${book.origin}', style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withAlpha(150),
                  )),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  if (chapters.isNotEmpty) {
                    context.push('/reader?bookId=$bookId&chapterIndex=${book.readChapterIndex}');
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(book.readChapterIndex > 0 ? '继续阅读 (${book.readChapterIndex + 1}/${chapters.length})' : '开始阅读'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Intro
        if (book.intro != null && book.intro!.isNotEmpty) ...[
          Text('简介', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(book.intro!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
          const SizedBox(height: 16),
        ],

        // Chapter list
        Row(
          children: [
            Text('目录 (${chapters.length}章)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {}, // toggle sort order
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (chapters.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('暂无章节目录')),
          )
        else
          ...chapters.take(50).map((chapter) => ListTile(
                dense: true,
                title: Text(chapter.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium),
                trailing: chapter.isVip
                    ? Icon(Icons.lock, size: 16, color: colorScheme.onSurface.withAlpha(120))
                    : null,
                onTap: () {
                  context.push('/reader?bookId=$bookId&chapterIndex=${chapter.index}');
                },
              )),

        if (chapters.length > 50)
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text('查看全部 ${chapters.length} 章'),
            ),
          ),

        const SizedBox(height: 80),
      ],
    );
  }
}
