import 'package:dio/dio.dart';
import 'package:gbk_codec/gbk_codec.dart';
import '../utils/charset_detector.dart';

class HttpFetcher {
  final Dio _dio;
  final Map<String, CookieJar> _cookieJars = {};

  HttpFetcher() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    responseType: ResponseType.bytes,
    followRedirects: true,
    maxRedirects: 5,
    headers: {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      'Accept': 'text/html,application/json,application/xhtml+xml,*/*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
    },
  ));

  /// Fetch a URL and return response as String, auto-detecting encoding.
  Future<FetchResult> fetch(String url, {Map<String, String>? headers, String? cookieKey}) async {
    final opts = Options(headers: headers);
    final response = await _dio.get<dynamic>(url, options: opts);
    final bytes = _extractBytes(response.data);
    final contentType = response.headers.value('content-type');

    String body;
    if (contentType != null && contentType.contains('json')) {
      body = CharsetDetector.decode(bytes, contentType: 'utf-8');
    } else {
      body = _decodeWithGBK(bytes, contentType: contentType);
    }

    return FetchResult(
      body: body,
      url: response.realUri.toString(),
      statusCode: response.statusCode ?? 0,
    );
  }

  /// Fetch with POST body (for search APIs)
  Future<FetchResult> post(String url, {Map<String, String>? headers, String? body}) async {
    final response = await _dio.post<dynamic>(
      url,
      data: body,
      options: Options(headers: headers),
    );
    final bytes = _extractBytes(response.data);
    final contentType = response.headers.value('content-type');

    String responseBody;
    if (contentType != null && contentType.contains('json')) {
      responseBody = CharsetDetector.decode(bytes, contentType: 'utf-8');
    } else {
      responseBody = _decodeWithGBK(bytes, contentType: contentType);
    }

    return FetchResult(
      body: responseBody,
      url: url,
      statusCode: response.statusCode ?? 0,
    );
  }

  /// Build absolute URL from base URL and relative path.
  String buildUrl(String baseUrl, String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('//')) {
      final scheme = baseUrl.startsWith('https') ? 'https:' : 'http:';
      return '$scheme$path';
    }
    if (path.startsWith('/')) {
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme}://${uri.host}$path';
    }
    if (!baseUrl.endsWith('/')) baseUrl += '/';
    return '$baseUrl$path';
  }

  List<int> _extractBytes(dynamic data) {
    if (data is List<int>) return data;
    if (data is String) return data.codeUnits;
    if (data is List) return List<int>.from(data);
    return [];
  }

  String _decodeWithGBK(List<int> bytes, {String? contentType}) {
    // Try to extract charset
    if (contentType != null) {
      final match = RegExp(r'charset=([^\s;]+)', caseSensitive: false).firstMatch(contentType);
      if (match != null) {
        final charset = match.group(1)!.toLowerCase();
        if (charset == 'gbk' || charset == 'gb2312' || charset == 'gb18030') {
          return gbk.decode(bytes, allowMalformed: true);
        }
        if (charset == 'big5') {
          return gbk.decode(bytes, allowMalformed: true);
        }
      }
    }

    // Try UTF-8 first
    try {
      final s = utf8.decode(bytes, allowMalformed: true);
      final replacementCount = '�'.allMatches(s).length;
      if (replacementCount < s.length * 0.1) return s;
    } catch (_) {}

    // Try GBK
    try {
      final s = gbk.decode(bytes, allowMalformed: true);
      return s;
    } catch (_) {}

    // Last resort
    return String.fromCharCodes(bytes);
  }

  void dispose() {
    _dio.close();
  }
}

/// Workaround: import dart:convert for utf8
import 'dart:convert';

class FetchResult {
  final String body;
  final String url;
  final int statusCode;

  const FetchResult({
    required this.body,
    required this.url,
    required this.statusCode,
  });
}

/// Simple cookie jar per source.
class CookieJar {
  final Map<String, String> _cookies = {};

  void setCookie(String key, String value) => _cookies[key] = value;
  String? getCookie(String key) => _cookies[key];

  String toHeaderString() {
    if (_cookies.isEmpty) return '';
    return _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }
}
