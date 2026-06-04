import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database.dart';
import '../../core/models/book_source.dart';
import '../../core/models/book.dart';

final bookshelfProvider = AsyncNotifierProvider<BookshelfNotifier, List<Book>>(BookshelfNotifier.new);

class BookshelfNotifier extends AsyncNotifier<List<Book>> {
  static const _uuid = Uuid();
  AppDatabase get _db => AppDatabase.instance;

  @override
  Future<List<Book>> build() async {
    return _db.getAllBooks();
  }

  Future<void> addBook(Book book) async {
    await _db.saveBook(book);
    ref.invalidateSelf();
  }

  Future<void> addBookFromSearch({
    required String name,
    required String author,
    String? coverUrl,
    String? intro,
    String? detailUrl,
    String? tocUrl,
    String? kind,
    String? wordCount,
    String? lastChapter,
    required String sourceName,
  }) async {
    final book = Book(
      id: _uuid.v4(),
      name: name,
      author: author,
      coverUrl: coverUrl,
      intro: intro,
      kind: kind,
      wordCount: wordCount,
      lastChapter: lastChapter,
      detailUrl: detailUrl,
      tocUrl: tocUrl,
      origin: sourceName,
      addTime: DateTime.now(),
      lastReadTime: DateTime.now(),
    );
    await _db.saveBook(book);
    ref.invalidateSelf();
  }

  Future<void> removeBook(String id) async {
    await _db.deleteBook(id);
    ref.invalidateSelf();
  }

  Future<void> updateProgress(String bookId, int chapterIndex, int pos) async {
    await _db.updateReadingProgress(bookId, chapterIndex, pos);
    ref.invalidateSelf();
  }

  Future<void> updateBookInfo(String bookId, {
    String? intro, String? kind, String? wordCount, String? lastChapter, String? updateTime, String? coverUrl,
  }) async {
    if (coverUrl != null) await _db.updateBookCover(bookId, coverUrl);
    await _db.updateBookIntro(bookId, intro, kind, wordCount, lastChapter, updateTime);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Source management provider
final sourceManageProvider = AsyncNotifierProvider<SourceManageNotifier, List<BookSource>>(SourceManageNotifier.new);

class SourceManageNotifier extends AsyncNotifier<List<BookSource>> {
  AppDatabase get _db => AppDatabase.instance;

  @override
  Future<List<BookSource>> build() async {
    return _db.getAllSources();
  }

  Future<void> importFromJson(String jsonStr) async {
    try {
      final source = BookSource.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      await _db.saveSource(source);
      ref.invalidateSelf();
    } catch (_) {}
  }

  Future<void> importList(String jsonArrayStr) async {
    try {
      final list = jsonDecode(jsonArrayStr);
      if (list is List) {
        final sources = list.map((e) => BookSource.fromJson(e as Map<String, dynamic>)).toList();
        await _db.saveSources(sources);
        ref.invalidateSelf();
      }
    } catch (_) {}
  }

  Future<void> toggle(String name, String url, bool enabled) async {
    await _db.toggleSource(name, url, enabled);
    ref.invalidateSelf();
  }

  Future<void> remove(String name, String url) async {
    await _db.deleteSource(name, url);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Discovery state
final discoveryProvider = FutureProvider.family<List<dynamic>, String>((ref, exploreUrl) async {
  // Will be implemented with RuleEngine
  return [];
});
