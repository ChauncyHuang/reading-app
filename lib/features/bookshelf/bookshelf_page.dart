import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/models/book.dart';
import 'bookshelf_provider.dart';

class BookshelfPage extends ConsumerStatefulWidget {
  const BookshelfPage({super.key});

  @override
  ConsumerState<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends ConsumerState<BookshelfPage> {
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bookshelfProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('书架'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/source-manage'),
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) return const _EmptyBookshelf();
          return _isGridView
              ? _BookshelfGrid(books: books)
              : _BookshelfList(books: books);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _EmptyBookshelf extends StatelessWidget {
  const _EmptyBookshelf();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book, size: 80, color: Theme.of(context).colorScheme.primary.withAlpha(100)),
          const SizedBox(height: 16),
          Text('书架空空如也', style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          )),
          const SizedBox(height: 8),
          Text('去搜索或发现页面找书吧', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
          )),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
            label: const Text('去搜索'),
          ),
        ],
      ),
    );
  }
}

class _BookshelfGrid extends StatelessWidget {
  final List<Book> books;
  const _BookshelfGrid({required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) => _BookGridItem(book: books[index]),
    );
  }
}

class _BookGridItem extends ConsumerWidget {
  final Book book;
  const _BookGridItem({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openBook(context, book),
      onLongPress: () => _showBookMenu(context, ref, book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.coverUrl != null
                  ? CachedNetworkImage(imageUrl: book.coverUrl!, fit: BoxFit.cover)
                  : Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(book.name[0], style: TextStyle(
                          fontSize: 32, color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(book.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall),
          if (book.readChapterIndex > 0)
            LinearProgressIndicator(value: 0.3, minHeight: 2),
        ],
      ),
    );
  }

  void _openBook(BuildContext context, Book book) {
    if (book.isLocal && book.localFilePath != null) {
      context.push('/reader?bookId=${book.id}&chapterIndex=0');
    } else {
      context.push('/book-detail?bookId=${book.id}');
    }
  }

  void _showBookMenu(BuildContext context, WidgetRef ref, Book book) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: const Text('继续阅读'),
            onTap: () { Navigator.pop(ctx); _openBook(context, book); },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('书籍详情'),
            onTap: () { Navigator.pop(ctx); context.push('/book-detail?bookId=${book.id}'); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('从书架删除'),
            onTap: () {
              Navigator.pop(ctx);
              ref.read(bookshelfProvider.notifier).removeBook(book.id);
            },
          ),
        ],
      ),
    );
  }
}

class _BookshelfList extends StatelessWidget {
  final List<Book> books;
  const _BookshelfList({required this.books});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: book.coverUrl != null
                ? CachedNetworkImage(imageUrl: book.coverUrl!, width: 48, height: 64, fit: BoxFit.cover)
                : Container(width: 48, height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(child: Text(book.name[0], style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary)))),
          ),
          title: Text(book.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${book.author}  ${DateFormat('MM-dd').format(book.lastReadTime)}'),
          trailing: Text('${book.readChapterIndex + 1}', style: Theme.of(context).textTheme.bodySmall),
          onTap: () => context.push('/book-detail?bookId=${book.id}'),
        );
      },
    );
  }
}
