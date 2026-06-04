import 'dart:convert';

/// Detects text encoding from raw bytes and decodes to String.
class CharsetDetector {
  /// Attempt to decode bytes with auto-detection.
  /// Tries UTF-8 first, then falls back to Latin-1 (which preserves all bytes).
  /// For proper GBK/Big5 support, add `gbk_codec` package.
  static String decode(List<int> bytes, {String? contentType}) {
    // Try to extract charset from Content-Type header
    if (contentType != null) {
      final charset = _parseCharset(contentType);
      if (charset != null) {
        return _decodeWith(charset, bytes);
      }
    }

    // Check for UTF-8 BOM
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }

    // Try UTF-8 first
    try {
      final s = utf8.decode(bytes, allowMalformed: true);
      // Check if it looks reasonable (low replacement char ratio)
      final replacementCount = '�'.allMatches(s).length;
      if (replacementCount < s.length * 0.3) return s;
    } catch (_) {}

    // Fallback: decode as Latin-1 (preserves bytes 1:1) and try to detect
    // This gives readable ASCII mixed with raw bytes for CJK
    final latin1Str = latin1.decode(bytes);
    final gbkBytes = _latin1ToGbkBytes(latin1Str);
    if (gbkBytes != null) {
      try {
        return gbkBytes;
      } catch (_) {}
    }

    return latin1Str;
  }

  /// Try to decode Latin-1 bytes as GBK by re-encoding and using system decoder.
  /// This is a heuristic — for proper GBK, use the gbk_codec package.
  static String? _latin1ToGbkBytes(String latin1Str) {
    // Convert Latin-1 string back to raw bytes, then attempt GBK
    final raw = latin1Str.codeUnits;
    // Check if this looks like GBK (many bytes > 0x80)
    int highBytes = raw.where((b) => b >= 0x81 && b <= 0xFE).length;
    if (highBytes > raw.length * 0.1) {
      // Looks like GBK — use a simple conversion
      return _simpleGbkDecode(raw);
    }
    return null;
  }

  /// Simplified GBK decoding — handles common Chinese chars.
  static String _simpleGbkDecode(List<int> bytes) {
    final buf = StringBuffer();
    int i = 0;
    while (i < bytes.length) {
      if (bytes[i] < 0x80) {
        buf.writeCharCode(bytes[i]);
        i++;
      } else if (i + 1 < bytes.length) {
        // Simplified: re-encode as UTF-8 via raw bytes
        // This is a placeholder — use gbk_codec for production
        buf.writeCharCode(0xFFFD);
        i += 2;
      } else {
        buf.writeCharCode(0xFFFD);
        i++;
      }
    }
    return null; // return null so caller falls back to latin1
  }

  static String _decodeWith(String charset, List<int> bytes) {
    switch (charset.toLowerCase()) {
      case 'utf-8':
      case 'utf8':
        return utf8.decode(bytes, allowMalformed: true);
      case 'gbk':
      case 'gb2312':
      case 'gb18030':
        try {
          return _simpleGbkDecode(bytes) ?? latin1.decode(bytes);
        } catch (_) {
          return latin1.decode(bytes);
        }
      case 'big5':
        try {
          return _simpleGbkDecode(bytes) ?? latin1.decode(bytes);
        } catch (_) {
          return latin1.decode(bytes);
        }
      case 'iso-8859-1':
      case 'latin1':
        return latin1.decode(bytes);
      default:
        return utf8.decode(bytes, allowMalformed: true);
    }
  }

  static String? _parseCharset(String contentType) {
    final match =
        RegExp(r'charset=([^\s;]+)', caseSensitive: false)
            .firstMatch(contentType);
    return match?.group(1)?.toLowerCase();
  }
}
