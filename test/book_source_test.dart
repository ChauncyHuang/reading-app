import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:reading_app/core/models/book_source.dart';

void main() {
  group('BookSource model', () {
    test('fromJson parses minimal source', () {
      final json = {
        'bookSourceName': 'TestSource',
        'bookSourceUrl': 'https://example.com',
      };
      final source = BookSource.fromJson(json);
      expect(source.bookSourceName, 'TestSource');
      expect(source.bookSourceUrl, 'https://example.com');
      expect(source.enabled, true);
      expect(source.bookSourceType, 0);
    });

    test('fromJson parses all rules', () {
      final json = {
        'bookSourceName': 'FullSource',
        'bookSourceUrl': 'https://full.example.com',
        'ruleSearch': {
          'bookList': 'div.book',
          'name': 'span.title',
          'author': 'span.author',
        },
        'ruleBookInfo': {
          'init': '#info',
          'name': 'h1',
          'author': 'span.author',
        },
        'ruleToc': {
          'chapterList': 'ul.chapters li',
          'chapterName': 'a',
          'chapterUrl': 'a@href',
        },
        'ruleContent': {
          'content': 'div.content',
        },
      };
      final source = BookSource.fromJson(json);
      expect(source.ruleSearch?.name, 'span.title');
      expect(source.ruleBookInfo?.name, 'h1');
      expect(source.ruleToc?.chapterUrl, 'a@href');
      expect(source.ruleContent?.content, 'div.content');
    });

    test('toJson roundtrips', () {
      final json = {
        'bookSourceName': 'RT',
        'bookSourceUrl': 'https://rt.example.com',
        'ruleSearch': {'name': 'n'},
      };
      final source = BookSource.fromJson(json);
      final roundtripped = source.toJson();
      expect(roundtripped['bookSourceName'], 'RT');
      expect(roundtripped['ruleSearch'], isA<Map>());
    });
  });
}
