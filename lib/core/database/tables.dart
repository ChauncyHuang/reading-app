import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'tables.drift.dart';

// --- BookSource table ---
class BookSources extends Table {
  TextColumn get name => text().named('bookSourceName')();
  TextColumn get url => text().named('bookSourceUrl')();
  TextColumn get group => text().named('bookSourceGroup').nullable()();
  TextColumn get comment => text().named('bookSourceComment').nullable()();
  IntColumn get type => integer().named('bookSourceType').withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get customOrder => integer().withDefault(const Constant(0))();
  IntColumn get weight => integer().withDefault(const Constant(0))();
  TextColumn get jsonData => text().named('jsonData')(); // full JSON string

  @override
  Set<Column> get primaryKey => {name, url};
}

// --- Book table ---
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get author => text()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get intro => text().nullable()();
  TextColumn get kind => text().nullable()();
  TextColumn get wordCount => text().nullable()();
  TextColumn get lastChapter => text().nullable()();
  TextColumn get updateTime => text().nullable()();
  TextColumn get detailUrl => text().nullable()();
  TextColumn get tocUrl => text().nullable()();
  TextColumn get origin => text()();
  IntColumn get readChapterIndex => integer().withDefault(const Constant(0))();
  IntColumn get readChapterPos => integer().withDefault(const Constant(0))();
  BoolColumn get isLocal => boolean().withDefault(const Constant(false))();
  TextColumn get localFilePath => text().nullable()();
  IntColumn get groupId => integer().withDefault(const Constant(0))();
  DateTimeColumn get addTime => dateTime()();
  DateTimeColumn get lastReadTime => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- Chapter table ---
class Chapters extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get name => text()();
  TextColumn get url => text()();
  IntColumn get index => integer()();
  BoolColumn get isVip => boolean().withDefault(const Constant(false))();
  BoolColumn get isPay => boolean().withDefault(const Constant(false))();
  TextColumn get content => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// --- BookGroup table ---
class BookGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
