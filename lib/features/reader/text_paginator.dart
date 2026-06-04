import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TextPaginator {
  final String text;
  final double pageWidth;
  final double pageHeight;
  final double padding;
  final TextStyle style;
  final double lineHeight;

  List<String> _pages = [];
  List<TextLine> _lines = [];

  TextPaginator({
    required this.text,
    required this.pageWidth,
    required this.pageHeight,
    this.padding = 20,
    required this.style,
    this.lineHeight = 1.6,
  }) {
    _layout();
  }

  List<String> get pages => _pages;
  int get pageCount => _pages.length;

  void _layout() {
    final usableWidth = pageWidth - padding * 2;
    final usableHeight = pageHeight - padding * 2;
    final lineSpacing = style.fontSize! * lineHeight;

    // Build text painter
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textDirection: TextDirection.ltr,
      fontSize: style.fontSize,
      fontFamily: style.fontFamily,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      maxLines: null,
    ))
      ..pushStyle(ui.TextStyle(
        fontSize: style.fontSize,
        fontFamily: style.fontFamily,
        fontWeight: style.fontWeight,
        fontStyle: style.fontStyle,
        color: style.color ?? const Color(0xFF000000),
        height: lineHeight,
      ))
      ..addText(text);

    final paragraph = paragraphBuilder.build()..layout(ui.ParagraphConstraints(width: usableWidth));

    final totalLines = paragraph.lines;
    final linesPerPage = (usableHeight / lineSpacing).floor();
    final totalPages = (totalLines.length / linesPerPage).ceil();

    _pages = List.generate(totalPages, (pageIndex) {
      final startLine = pageIndex * linesPerPage;
      final endLine = (startLine + linesPerPage).clamp(0, totalLines.length);
      final startOffset = totalLines[startLine].startOffset;
      final endOffset = endLine < totalLines.length
          ? totalLines[endLine].endOffset.clamp(0, text.length)
          : text.length;

      // Include slight overlap
      final actualEnd = endLine < totalLines.length && endLine > 0
          ? totalLines[endLine - 1].endOffset.clamp(0, text.length)
          : endOffset;

      return text.substring(startOffset, actualEnd).trimRight();
    });
  }

  void updateStyle(TextStyle newStyle) {
    // rebuild with new style
  }

  void updateSize(double width, double height) {
    pageWidth = width;
    pageHeight = height;
    _layout();
  }
}

class TextLine {
  final String text;
  final int startOffset;
  final int endOffset;

  const TextLine({required this.text, required this.startOffset, required this.endOffset});
}
