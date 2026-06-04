import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/book.dart';
import '../../core/models/chapter.dart';
import '../../core/models/book_source.dart';
import '../../core/rule_engine/rule_engine.dart';
import '../../core/database/database.dart';
import '../bookshelf/bookshelf_provider.dart';
import 'reader_settings.dart';
import 'text_paginator.dart';

class ReaderProvider extends StateNotifier<ReaderState> {
  final String bookId;

  ReaderProvider(this.bookId) : super(const ReaderState()) {
    _init();
  }

  AppDatabase get _db => AppDatabase.instance;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    final book = await _db.getBook(bookId);
    if (book == null) {
      state = state.copyWith(isLoading: false, error: 'Book not found');
      return;
    }

    final chapters = await _db.getChapters(bookId);
    final currentIndex = book.readChapterIndex.clamp(0, (chapters.length - 1).clamp(0, 999999));

    if (chapters.isEmpty) {
      state = state.copyWith(book: book, isLoading: false);
      return;
    }

    // Load current chapter content
    final chapter = chapters[currentIndex];
    if (chapter.content == null || chapter.content!.isEmpty) {
      // Fetch from source
      final sources = await _db.getAllSources();
      final source = sources.where((s) => s.bookSourceName == book.origin).firstOrNull;
      if (source != null) {
        final engine = RuleEngine();
        try {
          final content = await engine.fetchChapterContent(source, chapter.url);
          await _db.updateChapterContent(chapter.id, content);
          chapter = chapter.copyWith(content: content);
        } catch (_) {}
        engine.dispose();
      }
    }

    state = state.copyWith(
      book: book,
      chapters: chapters,
      currentChapterIndex: currentIndex,
      currentChapter: chapter,
      isLoading: false,
    );
  }

  Future<void> loadChapter(int index) async {
    if (index < 0 || index >= state.chapters.length) return;

    state = state.copyWith(isLoadingChapter: true, currentChapterIndex: index);

    var chapter = state.chapters[index];
    if (chapter.content == null || chapter.content!.isEmpty) {
      final sources = await _db.getAllSources();
      final source = sources.where((s) => s.bookSourceName == state.book!.origin).firstOrNull;
      if (source != null) {
        final engine = RuleEngine();
        try {
          final content = await engine.fetchChapterContent(source, chapter.url);
          await _db.updateChapterContent(chapter.id, content);
          chapter = chapter.copyWith(content: content);
          final updatedChapters = List<Chapter>.from(state.chapters);
          updatedChapters[index] = chapter;
          state = state.copyWith(chapters: updatedChapters);
        } catch (_) {}
        engine.dispose();
      }
    }

    state = state.copyWith(
      currentChapter: chapter,
      currentChapterIndex: index,
      currentPage: 0,
      isLoadingChapter: false,
    );

    // Save progress
    await _db.updateReadingProgress(bookId, index, 0);
  }

  void setCurrentPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  Future<void> saveProgress(int charPos) async {
    await _db.updateReadingProgress(bookId, state.currentChapterIndex, charPos);
  }

  void toggleSettingsPanel() {
    state = state.copyWith(showSettings: !state.showSettings);
  }
}

class ReaderState {
  final Book? book;
  final List<Chapter> chapters;
  final Chapter? currentChapter;
  final int currentChapterIndex;
  final int currentPage;
  final bool isLoading;
  final bool isLoadingChapter;
  final bool showSettings;
  final String? error;

  const ReaderState({
    this.book,
    this.chapters = const [],
    this.currentChapter,
    this.currentChapterIndex = 0,
    this.currentPage = 0,
    this.isLoading = false,
    this.isLoadingChapter = false,
    this.showSettings = false,
    this.error,
  });

  ReaderState copyWith({
    Book? book,
    List<Chapter>? chapters,
    Chapter? currentChapter,
    int? currentChapterIndex,
    int? currentPage,
    bool? isLoading,
    bool? isLoadingChapter,
    bool? showSettings,
    String? error,
  }) {
    return ReaderState(
      book: book ?? this.book,
      chapters: chapters ?? this.chapters,
      currentChapter: currentChapter ?? this.currentChapter,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingChapter: isLoadingChapter ?? this.isLoadingChapter,
      showSettings: showSettings ?? this.showSettings,
      error: error,
    );
  }
}
