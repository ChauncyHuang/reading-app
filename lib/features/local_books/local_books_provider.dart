import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/book.dart';
import '../../core/database/database.dart';
import '../../core/utils/charset_detector.dart';

final localBooksProvider = AsyncNotifierProvider<LocalBooksNotifier, List<Book>>(LocalBooksNotifier.new);

class LocalBooksNotifier extends AsyncNotifier<List<Book>> {
  static const _uuid = Uuid();
  AppDatabase get _db => AppDatabase.instance;

  @override
  Future<List<Book>> build() async {
    return _db.getAllBooks().then((books) => books.where((b) => b.isLocal).toList());
  }

  Future<void> importTxt(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    final content = CharsetDetector.decode(bytes);

    final fileName = filePath.split(Platform.pathSeparator).last.replaceAll('.txt', '');
    final book = Book(
      id: _uuid.v4(),
      name: fileName,
      author: '本地书籍',
      isLocal: true,
      localFilePath: filePath,
      origin: '本地',
      addTime: DateTime.now(),
      lastReadTime: DateTime.now(),
    );

    await _db.saveBook(book);

    // Create a single chapter from the txt content
    await _db.saveChapter(Chapter(
      id: '${book.id}-00000',
      bookId: book.id,
      name: fileName,
      url: filePath,
      index: 0,
      content: content,
    ));

    ref.invalidateSelf();
  }

  Future<void> importEpub(String filePath) async {
    // Use epub_parser package when available
    final file = File(filePath);
    if (!await file.exists()) return;

    final fileName = filePath.split(Platform.pathSeparator).last.replaceAll('.epub', '');
    final book = Book(
      id: _uuid.v4(),
      name: fileName,
      author: '本地书籍',
      isLocal: true,
      localFilePath: filePath,
      origin: '本地',
      addTime: DateTime.now(),
      lastReadTime: DateTime.now(),
    );

    await _db.saveBook(book);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
