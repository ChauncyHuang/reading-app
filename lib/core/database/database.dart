import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/book_source.dart';
import '../models/book.dart';
import '../models/chapter.dart';

class AppDatabase {
  static AppDatabase? _instance;
  late Database _db;

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Future<void> init(String dbPath) async {
    _db = await openDatabase(
      p.join(dbPath, 'reading_app.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE book_sources (
            name TEXT NOT NULL,
            url TEXT NOT NULL,
            "group" TEXT,
            comment TEXT,
            type INTEGER DEFAULT 0,
            enabled INTEGER DEFAULT 1,
            custom_order INTEGER DEFAULT 0,
            weight INTEGER DEFAULT 0,
            json_data TEXT NOT NULL,
            PRIMARY KEY (name, url)
          )
        ''');
        await db.execute('''
          CREATE TABLE books (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            author TEXT NOT NULL,
            cover_url TEXT,
            intro TEXT,
            kind TEXT,
            word_count TEXT,
            last_chapter TEXT,
            update_time TEXT,
            detail_url TEXT,
            toc_url TEXT,
            origin TEXT NOT NULL,
            read_chapter_index INTEGER DEFAULT 0,
            read_chapter_pos INTEGER DEFAULT 0,
            is_local INTEGER DEFAULT 0,
            local_file_path TEXT,
            group_id INTEGER DEFAULT 0,
            add_time INTEGER NOT NULL,
            last_read_time INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE chapters (
            id TEXT PRIMARY KEY,
            book_id TEXT NOT NULL,
            name TEXT NOT NULL,
            url TEXT NOT NULL,
            idx INTEGER NOT NULL,
            is_vip INTEGER DEFAULT 0,
            is_pay INTEGER DEFAULT 0,
            content TEXT
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_chapters_book ON chapters(book_id, idx)
        ''');
        await db.execute('''
          CREATE TABLE book_groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            sort_order INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // ========== Book Sources ==========

  Future<List<BookSource>> getAllSources() async {
    final rows = await _db.query('book_sources', orderBy: 'custom_order');
    return rows.map((r) => BookSource.fromJson(jsonDecode(r['json_data'] as String))).toList();
  }

  Future<List<BookSource>> getEnabledSources() async {
    final rows = await _db.query('book_sources',
        where: 'enabled = 1', orderBy: 'custom_order');
    return rows.map((r) => BookSource.fromJson(jsonDecode(r['json_data'] as String))).toList();
  }

  Future<void> saveSource(BookSource source) async {
    await _db.insert(
      'book_sources',
      {
        'name': source.bookSourceName,
        'url': source.bookSourceUrl,
        'group': source.bookSourceGroup,
        'comment': source.bookSourceComment,
        'type': source.bookSourceType,
        'enabled': source.enabled ? 1 : 0,
        'custom_order': source.customOrder,
        'weight': source.weight,
        'json_data': const JsonEncoder().convert(source.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveSources(List<BookSource> sources) async {
    final batch = _db.batch();
    for (final source in sources) {
      batch.insert(
        'book_sources',
        {
          'name': source.bookSourceName,
          'url': source.bookSourceUrl,
          'group': source.bookSourceGroup,
          'comment': source.bookSourceComment,
          'type': source.bookSourceType,
          'enabled': source.enabled ? 1 : 0,
          'custom_order': source.customOrder,
          'weight': source.weight,
          'json_data': const JsonEncoder().convert(source.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> toggleSource(String name, String url, bool enabled) async {
    await _db.update(
      'book_sources',
      {'enabled': enabled ? 1 : 0},
      where: 'name = ? AND url = ?',
      whereArgs: [name, url],
    );
  }

  Future<void> deleteSource(String name, String url) async {
    await _db.delete('book_sources', where: 'name = ? AND url = ?', whereArgs: [name, url]);
  }

  // ========== Books ==========

  Future<List<Book>> getAllBooks({String orderBy = 'last_read_time DESC'}) async {
    final rows = await _db.query('books', orderBy: orderBy);
    return rows.map(_bookFromRow).toList();
  }

  Future<List<Book>> getBooksByGroup(int groupId, {String orderBy = 'last_read_time DESC'}) async {
    final rows = await _db.query('books', where: 'group_id = ?', whereArgs: [groupId], orderBy: orderBy);
    return rows.map(_bookFromRow).toList();
  }

  Future<Book?> getBook(String id) async {
    final rows = await _db.query('books', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _bookFromRow(rows.first);
  }

  Future<void> saveBook(Book book) async {
    await _db.insert(
      'books',
      _bookToRow(book),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateReadingProgress(String bookId, int chapterIndex, int charPos) async {
    await _db.update(
      'books',
      {
        'read_chapter_index': chapterIndex,
        'read_chapter_pos': charPos,
        'last_read_time': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<void> deleteBook(String id) async {
    await _db.delete('books', where: 'id = ?', whereArgs: [id]);
    await _db.delete('chapters', where: 'book_id = ?', whereArgs: [id]);
  }

  Future<void> updateBookCover(String bookId, String coverUrl) async {
    await _db.update('books', {'cover_url': coverUrl}, where: 'id = ?', whereArgs: [bookId]);
  }

  Future<void> updateBookIntro(String bookId, String? intro, String? kind, String? wordCount, String? lastChapter, String? updateTime) async {
    await _db.update('books', {
      'intro': intro,
      'kind': kind,
      'word_count': wordCount,
      'last_chapter': lastChapter,
      'update_time': updateTime,
    }, where: 'id = ?', whereArgs: [bookId]);
  }

  // ========== Chapters ==========

  Future<List<Chapter>> getChapters(String bookId) async {
    final rows = await _db.query('chapters',
        where: 'book_id = ?', whereArgs: [bookId], orderBy: 'idx');
    return rows.map(_chapterFromRow).toList();
  }

  Future<Chapter?> getChapter(String id) async {
    final rows = await _db.query('chapters', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _chapterFromRow(rows.first);
  }

  Future<Chapter?> getChapterByIndex(String bookId, int index) async {
    final rows = await _db.query('chapters',
        where: 'book_id = ? AND idx = ?', whereArgs: [bookId, index]);
    if (rows.isEmpty) return null;
    return _chapterFromRow(rows.first);
  }

  Future<Chapter?> getFirstChapter(String bookId) async {
    final rows = await _db.query('chapters',
        where: 'book_id = ?', whereArgs: [bookId], orderBy: 'idx', limit: 1);
    if (rows.isEmpty) return null;
    return _chapterFromRow(rows.first);
  }

  Future<int> getChapterCount(String bookId) async {
    final result = await _db.rawQuery(
        'SELECT COUNT(*) as cnt FROM chapters WHERE book_id = ?', [bookId]);
    return result.first['cnt'] as int;
  }

  Future<void> saveChapter(Chapter chapter) async {
    await _db.insert(
      'chapters',
      _chapterToRow(chapter),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveChapters(List<Chapter> chapters) async {
    final batch = _db.batch();
    for (final chapter in chapters) {
      batch.insert('chapters', _chapterToRow(chapter), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateChapterContent(String id, String content) async {
    await _db.update('chapters', {'content': content}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearChapterContent(String bookId) async {
    await _db.update('chapters', {'content': null}, where: 'book_id = ?', whereArgs: [bookId]);
  }

  // ========== Book Groups ==========

  Future<List<Map<String, dynamic>>> getAllGroups() async {
    return _db.query('book_groups', orderBy: 'sort_order');
  }

  Future<int> addGroup(String name, {int sortOrder = 0}) async {
    return _db.insert('book_groups', {'name': name, 'sort_order': sortOrder});
  }

  Future<void> deleteGroup(int id) async {
    await _db.delete('book_groups', where: 'id = ?', whereArgs: [id]);
    // move books in this group back to default
    await _db.update('books', {'group_id': 0}, where: 'group_id = ?', whereArgs: [id]);
  }

  // ========== Row conversion ==========

  Book _bookFromRow(Map<String, dynamic> r) {
    return Book(
      id: r['id'] as String,
      name: r['name'] as String,
      author: r['author'] as String,
      coverUrl: r['cover_url'] as String?,
      intro: r['intro'] as String?,
      kind: r['kind'] as String?,
      wordCount: r['word_count'] as String?,
      lastChapter: r['last_chapter'] as String?,
      updateTime: r['update_time'] as String?,
      detailUrl: r['detail_url'] as String?,
      tocUrl: r['toc_url'] as String?,
      origin: r['origin'] as String,
      readChapterIndex: r['read_chapter_index'] as int? ?? 0,
      readChapterPos: r['read_chapter_pos'] as int? ?? 0,
      isLocal: (r['is_local'] as int? ?? 0) == 1,
      localFilePath: r['local_file_path'] as String?,
      groupId: r['group_id'] as int? ?? 0,
      addTime: DateTime.fromMillisecondsSinceEpoch(r['add_time'] as int),
      lastReadTime: DateTime.fromMillisecondsSinceEpoch(r['last_read_time'] as int),
    );
  }

  Map<String, dynamic> _bookToRow(Book book) {
    return {
      'id': book.id,
      'name': book.name,
      'author': book.author,
      'cover_url': book.coverUrl,
      'intro': book.intro,
      'kind': book.kind,
      'word_count': book.wordCount,
      'last_chapter': book.lastChapter,
      'update_time': book.updateTime,
      'detail_url': book.detailUrl,
      'toc_url': book.tocUrl,
      'origin': book.origin,
      'read_chapter_index': book.readChapterIndex,
      'read_chapter_pos': book.readChapterPos,
      'is_local': book.isLocal ? 1 : 0,
      'local_file_path': book.localFilePath,
      'group_id': book.groupId,
      'add_time': book.addTime.millisecondsSinceEpoch,
      'last_read_time': book.lastReadTime.millisecondsSinceEpoch,
    };
  }

  Chapter _chapterFromRow(Map<String, dynamic> r) {
    return Chapter(
      id: r['id'] as String,
      bookId: r['book_id'] as String,
      name: r['name'] as String,
      url: r['url'] as String,
      index: r['idx'] as int? ?? 0,
      isVip: (r['is_vip'] as int? ?? 0) == 1,
      isPay: (r['is_pay'] as int? ?? 0) == 1,
      content: r['content'] as String?,
    );
  }

  Map<String, dynamic> _chapterToRow(Chapter chapter) {
    return {
      'id': chapter.id,
      'book_id': chapter.bookId,
      'name': chapter.name,
      'url': chapter.url,
      'idx': chapter.index,
      'is_vip': chapter.isVip ? 1 : 0,
      'is_pay': chapter.isPay ? 1 : 0,
      'content': chapter.content,
    };
  }
}
