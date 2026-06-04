import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/database.dart';
import '../../core/models/book_source.dart';
import '../../core/models/book.dart';

class BackupService {
  final AppDatabase _db = AppDatabase.instance;

  Future<String> exportBackup() async {
    final books = await _db.getAllBooks();
    final sources = await _db.getAllSources();
    final groups = await _db.getAllGroups();

    final backupData = {
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'books': books.map((b) => {
            'id': b.id,
            'name': b.name,
            'author': b.author,
            'coverUrl': b.coverUrl,
            'intro': b.intro,
            'kind': b.kind,
            'wordCount': b.wordCount,
            'lastChapter': b.lastChapter,
            'updateTime': b.updateTime,
            'detailUrl': b.detailUrl,
            'tocUrl': b.tocUrl,
            'origin': b.origin,
            'readChapterIndex': b.readChapterIndex,
            'readChapterPos': b.readChapterPos,
            'isLocal': b.isLocal,
            'localFilePath': b.localFilePath,
            'groupId': b.groupId,
            'addTime': b.addTime.toIso8601String(),
            'lastReadTime': b.lastReadTime.toIso8601String(),
          }).toList(),
      'sources': sources.map((s) => s.toJson()).toList(),
      'groups': groups,
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  Future<int> importBackup(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    int count = 0;

    // Import sources
    if (data['sources'] is List) {
      final sources = (data['sources'] as List)
          .map((e) => BookSource.fromJson(e as Map<String, dynamic>))
          .toList();
      await _db.saveSources(sources);
      count += sources.length;
    }

    // Import books
    if (data['books'] is List) {
      for (final b in (data['books'] as List)) {
        final book = Book(
          id: b['id'] as String,
          name: b['name'] as String,
          author: b['author'] as String,
          coverUrl: b['coverUrl'] as String?,
          intro: b['intro'] as String?,
          kind: b['kind'] as String?,
          wordCount: b['wordCount'] as String?,
          lastChapter: b['lastChapter'] as String?,
          updateTime: b['updateTime'] as String?,
          detailUrl: b['detailUrl'] as String?,
          tocUrl: b['tocUrl'] as String?,
          origin: b['origin'] as String,
          readChapterIndex: b['readChapterIndex'] as int? ?? 0,
          readChapterPos: b['readChapterPos'] as int? ?? 0,
          isLocal: b['isLocal'] as bool? ?? false,
          localFilePath: b['localFilePath'] as String?,
          groupId: b['groupId'] as int? ?? 0,
          addTime: DateTime.tryParse(b['addTime'] as String? ?? '') ?? DateTime.now(),
          lastReadTime: DateTime.tryParse(b['lastReadTime'] as String? ?? '') ?? DateTime.now(),
        );
        await _db.saveBook(book);
        count++;
      }
    }

    return count;
  }

  Future<void> saveToFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  Future<String> readFromFile(String path) async {
    final file = File(path);
    return file.readAsString();
  }
}
