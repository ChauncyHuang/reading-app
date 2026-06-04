import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'text_paginator.dart';
import '../../shared/theme/app_theme.dart';

/// Reading settings managed by provider.
class ReaderSettings {
  final double fontSize;
  final String fontFamily;
  final int bgColorIndex;
  final double brightness;
  final double lineHeight;
  final double paragraphSpacing;
  final double marginLeft;
  final double marginRight;
  final PageTurnMode pageTurnMode;

  const ReaderSettings({
    this.fontSize = 18,
    this.fontFamily = '',
    this.bgColorIndex = 1,
    this.brightness = 0.8,
    this.lineHeight = 1.6,
    this.paragraphSpacing = 8,
    this.marginLeft = 20,
    this.marginRight = 20,
    this.pageTurnMode = PageTurnMode.cover,
  });

  Color get bgColor => AppTheme.readerBgColors[bgColorIndex.clamp(0, AppTheme.readerBgColors.length - 1)];
  Color get textColor => AppTheme.readerTextColors[bgColorIndex.clamp(0, AppTheme.readerTextColors.length - 1)];

  TextStyle get textStyle => TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily.isEmpty ? null : fontFamily,
        color: textColor,
        height: lineHeight,
        decoration: TextDecoration.none,
      );

  ReaderSettings copyWith({
    double? fontSize,
    String? fontFamily,
    int? bgColorIndex,
    double? brightness,
    double? lineHeight,
    double? paragraphSpacing,
    double? marginLeft,
    double? marginRight,
    PageTurnMode? pageTurnMode,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      bgColorIndex: bgColorIndex ?? this.bgColorIndex,
      brightness: brightness ?? this.brightness,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      pageTurnMode: pageTurnMode ?? this.pageTurnMode,
    );
  }
}

enum PageTurnMode { cover, slide, scroll }

final readerSettingsProvider = StateProvider<ReaderSettings>((ref) => const ReaderSettings());
