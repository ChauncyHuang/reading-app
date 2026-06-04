import 'package:html/dom.dart' as html_dom;
import '../../core/models/book_source.dart';
import '../../core/models/search_result.dart';
import '../../core/models/chapter.dart';
import 'http_fetcher.dart';
import 'rule_parser.dart';
import 'js_executor.dart';

class RuleEngine {
  final HttpFetcher _http = HttpFetcher();
  final RuleParser _parser = RuleParser();
  final JsExecutor _js = JsExecutor();

  RuleEngine() {
    _js.init();
  }

  HttpFetcher get http => _http;

  // ==================== SEARCH ====================

  /// Search a book source for books matching [keyword].
  Future<List<SearchResult>> search(BookSource source, String keyword, {int page = 1}) async {
    final context = {
      'key': keyword,
      'page': page.toString(),
      'baseUrl': source.bookSourceUrl,
    };

    // Build search URL
    String searchUrl;
    if (source.searchUrl != null) {
      searchUrl = await _js.evalSearchUrl(source.searchUrl, context);
    } else if (source.bookSourceUrl.contains('?')) {
      searchUrl = '${source.bookSourceUrl}&keyword=$keyword&page=$page';
    } else {
      searchUrl = await _buildSearchUrl(source, keyword, page);
    }

    if (searchUrl.isEmpty) return [];

    // Fix relative URL
    searchUrl = _http.buildUrl(source.bookSourceUrl, searchUrl);

    final result = await _http.fetch(searchUrl);
    if (result.body.isEmpty) return [];

    final searchHtml = result.body;

    if (source.ruleSearch == null) return [];

    // Find book list elements
    final elements = _parser.selectElements(searchHtml, source.ruleSearch!.bookList);
    if (elements.isEmpty) return [];

    // For JSON responses, parse differently
    if (source.ruleSearch!.bookList?.startsWith(r'$.') == true) {
      return _parseJsonSearchResults(searchHtml, source.ruleSearch!, source);
    }

    // Parse each book element
    final rules = _searchRulesMap(source.ruleSearch!);
    final results = <SearchResult>[];
    for (final element in elements) {
      final parsed = _parser.parseElement(element, rules);
      final name = parsed['name'] ?? '';
      final author = parsed['author'] ?? '';
      if (name.isEmpty) continue;

      results.add(SearchResult(
        name: name,
        author: author,
        coverUrl: _http.buildUrl(source.bookSourceUrl, parsed['coverUrl'] ?? ''),
        detailUrl: parsed['detailUrl'] != null
            ? _http.buildUrl(source.bookSourceUrl, parsed['detailUrl']!)
            : null,
        kind: parsed['kind'],
        wordCount: parsed['wordCount'],
        lastChapter: parsed['lastChapter'],
        intro: parsed['intro'],
        sourceName: source.bookSourceName,
        sourceUrl: source.bookSourceUrl,
      ));
    }
    return results;
  }

  // ==================== BOOK INFO ====================

  /// Fetch detailed book information from the detail page.
  Future<Map<String, String?>> fetchBookInfo(BookSource source, String detailUrl) async {
    final fullUrl = _http.buildUrl(source.bookSourceUrl, detailUrl);
    final result = await _http.fetch(fullUrl);

    // Execute init rule if JS
    var html = result.body;
    if (source.ruleBookInfo?.init != null) {
      final initResult = await _js.evalJsRule(source.ruleBookInfo!.init, {
        'baseUrl': source.bookSourceUrl,
        'result': html,
      });
      if (initResult.isNotEmpty) html = initResult;
    }

    final rules = <String, String?>{};
    if (source.ruleBookInfo != null) {
      rules['name'] = source.ruleBookInfo!.name;
      rules['author'] = source.ruleBookInfo!.author;
      rules['coverUrl'] = source.ruleBookInfo!.coverUrl;
      rules['intro'] = source.ruleBookInfo!.intro;
      rules['kind'] = source.ruleBookInfo!.kind;
      rules['wordCount'] = source.ruleBookInfo!.wordCount;
      rules['lastChapter'] = source.ruleBookInfo!.lastChapter;
      rules['updateTime'] = source.ruleBookInfo!.updateTime;
      rules['tocUrl'] = source.ruleBookInfo!.tocUrl;
    }

    return _parser.evaluateAll(html, rules);
  }

  // ==================== TABLE OF CONTENTS ====================

  /// Fetch chapter list for a book.
  Future<List<Chapter>> fetchChapterList(BookSource source, String tocUrl, String bookId) async {
    final fullUrl = _http.buildUrl(source.bookSourceUrl, tocUrl);
    final result = await _http.fetch(fullUrl);

    if (source.ruleToc == null) return [];

    final elements = _parser.selectElements(result.body, source.ruleToc!.chapterList);
    if (elements.isEmpty) return [];

    final tocRules = <String, String?>{
      'chapterName': source.ruleToc!.chapterName,
      'chapterUrl': source.ruleToc!.chapterUrl,
    };

    final chapters = <Chapter>[];
    for (int i = 0; i < elements.length; i++) {
      final parsed = _parser.parseElement(elements[i], tocRules);
      final name = parsed['chapterName'] ?? '';
      final url = parsed['chapterUrl'] ?? '';
      if (name.isEmpty) continue;

      final fullChapterUrl = _http.buildUrl(source.bookSourceUrl, url);

      chapters.add(Chapter(
        id: '$bookId-${i.toString().padLeft(5, '0')}',
        bookId: bookId,
        name: name,
        url: fullChapterUrl,
        index: i,
      ));
    }
    return chapters;
  }

  // ==================== CHAPTER CONTENT ====================

  /// Fetch chapter content.
  Future<String> fetchChapterContent(BookSource source, String chapterUrl) async {
    final fullUrl = _http.buildUrl(source.bookSourceUrl, chapterUrl);
    final result = await _http.fetch(fullUrl);

    if (source.ruleContent == null) return result.body;

    // Handle @js: in content rule
    var contentRule = source.ruleContent!.content;
    var html = result.body;

    if (JsExecutor.isJsRule(contentRule)) {
      final jsResult = await _js.evalJsRule(contentRule!, {
        'baseUrl': source.bookSourceUrl,
        'result': html,
      });
      html = jsResult;
      contentRule = null; // already processed
    }

    final content = _parser.extractContent(html, contentRule, source.ruleContent!.replaceRegex);
    return content ?? html;
  }

  // ==================== DISCOVERY ====================

  /// Fetch discovery/explore items from a source.
  Future<List<SearchResult>> discover(BookSource source, String exploreUrl, {int page = 1}) async {
    final context = {
      'baseUrl': source.bookSourceUrl,
      'page': page.toString(),
    };

    String fullUrl;
    if (JsExecutor.isJsRule(exploreUrl)) {
      fullUrl = await _js.evalSearchUrl(exploreUrl, context);
    } else {
      fullUrl = _http.buildUrl(source.bookSourceUrl, exploreUrl);
    }

    final result = await _http.fetch(fullUrl);
    if (source.ruleExplore == null) return [];

    final elements = _parser.selectElements(result.body, source.ruleExplore!.bookList);
    if (elements.isEmpty) return [];

    final rules = _exploreRulesMap(source.ruleExplore!);
    final results = <SearchResult>[];
    for (final element in elements) {
      final parsed = _parser.parseElement(element, rules);
      final name = parsed['name'] ?? '';
      if (name.isEmpty) continue;
      results.add(SearchResult(
        name: name,
        author: parsed['author'] ?? '',
        coverUrl: parsed['coverUrl'] != null
            ? _http.buildUrl(source.bookSourceUrl, parsed['coverUrl']!)
            : null,
        detailUrl: parsed['detailUrl'] != null
            ? _http.buildUrl(source.bookSourceUrl, parsed['detailUrl']!)
            : null,
        kind: parsed['kind'],
        sourceName: source.bookSourceName,
        sourceUrl: source.bookSourceUrl,
      ));
    }
    return results;
  }

  // ==================== HELPERS ====================

  Map<String, String?> _searchRulesMap(RuleSearch rs) {
    return {
      'name': rs.name,
      'author': rs.author,
      'coverUrl': rs.coverUrl,
      'detailUrl': rs.detailUrl,
      'kind': rs.kind,
      'wordCount': rs.wordCount,
      'lastChapter': rs.lastChapter,
      'intro': rs.intro,
    };
  }

  Map<String, String?> _exploreRulesMap(RuleExplore re) {
    return {
      'name': re.name,
      'author': re.author,
      'coverUrl': re.coverUrl,
      'detailUrl': re.detailUrl,
      'kind': re.kind,
      'wordCount': re.wordCount,
      'lastChapter': re.lastChapter,
    };
  }

  Future<String> _buildSearchUrl(BookSource source, String keyword, int page) async {
    // Common search URL patterns for Chinese novel sites
    final url = source.bookSourceUrl;
    if (url.contains('biquge') || url.contains('xbiquge')) {
      return '$url/modules/article/search.php?searchkey=$keyword';
    }
    if (url.contains('qidian')) {
      return '$url/search?kw=$keyword';
    }
    return '$url/search?keyword=$keyword&page=$page';
  }

  List<SearchResult> _parseJsonSearchResults(String jsonStr, RuleSearch rs, BookSource source) {
    // Basic JSON search result parsing
    final results = <SearchResult>[];
    try {
      // Simple JSON parsing using dart:convert
      final dynamic data;
      // Try to extract JSON from the response
      final jsonStart = jsonStr.indexOf('{');
      final jsonStartArr = jsonStr.indexOf('[');
      if (jsonStartArr >= 0 && (jsonStart == -1 || jsonStartArr < jsonStart)) {
        data = _parseSimpleJsonArray(jsonStr.substring(jsonStartArr));
      } else if (jsonStart >= 0) {
        data = _parseSimpleJsonObject(jsonStr.substring(jsonStart));
      } else {
        return results;
      }

      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final name = _resolveJsonRule(item, rs.name);
            final author = _resolveJsonRule(item, rs.author);
            if (name != null && name.isNotEmpty) {
              results.add(SearchResult(
                name: name,
                author: author ?? '',
                coverUrl: _resolveJsonRule(item, rs.coverUrl),
                detailUrl: _resolveJsonRule(item, rs.detailUrl),
                kind: _resolveJsonRule(item, rs.kind),
                wordCount: _resolveJsonRule(item, rs.wordCount),
                lastChapter: _resolveJsonRule(item, rs.lastChapter),
                intro: _resolveJsonRule(item, rs.intro),
                sourceName: source.bookSourceName,
                sourceUrl: source.bookSourceUrl,
              ));
            }
          }
        }
      }
    } catch (_) {}
    return results;
  }

  dynamic _parseSimpleJsonArray(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) return decoded;
      return [];
    } catch (e) {
      debugPrint('JSON array parse error: $e');
      return [];
    }
  }

  Map<String, dynamic> _parseSimpleJsonObject(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (e) {
      debugPrint('JSON object parse error: $e');
      return {};
    }
  }

  String? _resolveJsonRule(Map<String, dynamic> item, String? rule) {
    if (rule == null) return null;
    // Support simple JSONPath: title, author.name, etc.
    final parts = rule.split('.');
    dynamic current = item;
    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current?.toString();
  }

  void dispose() {
    _http.dispose();
    _js.dispose();
  }
}
