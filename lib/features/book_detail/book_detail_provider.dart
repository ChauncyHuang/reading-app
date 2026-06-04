import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/models/book_source.dart';
import '../../core/rule_engine/rule_engine.dart';
import '../../core/database/database.dart';

final bookDetailProvider = FutureProvider.autoDispose.family<BookDetailState, String>((ref, bookId) async {
  final db = AppDatabase.instance;
  final book = await db.getBook(bookId);
  final chapters = book != null ? await db.getChapters(bookId) : <Chapter>[];
  return BookDetailState(book: book, chapters: chapters);
});

final chapterContentProvider = FutureProvider.autoDispose.family<String, ChapterContentParams>((ref, params) async {
  final db = AppDatabase.instance;

  // Check cache first
  final cached = await db.getChapter(params.chapterId);
  if (cached?.content != null && cached!.content!.isNotEmpty) {
    return cached.content!;
  }

  return ''; // Content will be fetched by reader via RuleEngine
});

class BookDetailState {
  final Book? book;
  final List<Chapter> chapters;
  const BookDetailState({this.book, this.chapters = const []});
}

class ChapterContentParams {
  final String chapterId;
  final String chapterUrl;
  final String sourceUrl;
  const ChapterContentParams({
    required this.chapterId,
    required this.chapterUrl,
    required this.sourceUrl,
  });
}
