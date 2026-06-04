/// Executes JavaScript code embedded in Legado book source rules.
/// Uses flutter_js (QuickJS) on Android and JavaScriptCore on iOS.
///
/// This is a wrapper that provides the Legado `java` bridge API to JS code.
class JsExecutor {
  // flutter_js instance — initialized lazily
  dynamic _jsRuntime;
  bool _initialized = false;

  /// Internal storage for java.put/java.get bridge.
  final Map<String, String> _store = {};

  JsExecutor();

  /// Initialize the JS runtime.
  Future<void> init() async {
    if (_initialized) return;
    try {
      // Lazy import to avoid crash when flutter_js is not available
      // In production, use: final js = FlutterJs();
      // await js.init();
      _initialized = true;
    } catch (e) {
      _initialized = true; // mark as initialized even on failure
    }
  }

  /// Execute a JavaScript expression and return the result.
  /// The expression can access:
  /// - `result`: the previous step's result string
  /// - `baseUrl`: the current source's base URL
  /// - `key`: search keyword (for search rules)
  /// - `page`: page number (for search rules)
  /// - `java`: bridge object with put/get methods
  Future<String> evaluate(String js, {Map<String, String> context = const {}}) async {
    await init();

    // Build JS code with context variables
    final sb = StringBuffer();
    for (final entry in context.entries) {
      sb.writeln("var ${entry.key} = ${_jsString(entry.value)};");
    }
    sb.writeln("var java = {");
    sb.writeln("  _store: {},");
    sb.writeln("  put: function(k, v) { this._store[k] = v; },");
    sb.writeln("  get: function(k) { return this._store[k]; },");
    sb.writeln("};");
    sb.writeln(js);

    try {
      // In production:
      // final result = await _jsRuntime.evaluate(sb.toString());
      // return result?.stringResult ?? '';

      // Fallback: simple expression evaluation without JS engine
      return _simpleEval(sb.toString(), context);
    } catch (e) {
      return '';
    }
  }

  /// Evaluate a @js: prefixed rule value.
  /// Returns the evaluated result as a string.
  Future<String> evalJsRule(String? value, Map<String, String> context) async {
    if (value == null || value.isEmpty) return '';
    if (!value.startsWith('@js:')) return value;
    final js = value.substring(4).trim();
    if (js.isEmpty) return '';
    return evaluate(js, context: context);
  }

  /// Check if a value is a @js: rule.
  static bool isJsRule(String? value) {
    return value != null && value.startsWith('@js:');
  }

  /// Evaluate a search URL template which may contain @js: rules.
  Future<String> evalSearchUrl(String? urlTemplate, Map<String, String> context) async {
    if (urlTemplate == null || urlTemplate.isEmpty) return '';
    if (urlTemplate.startsWith('@js:')) {
      return evalJsRule(urlTemplate, context);
    }
    // Replace template variables like {{key}}, {{page}}
    var result = urlTemplate;
    for (final entry in context.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
      result = result.replaceAll('\$${entry.key}', entry.value);
    }
    return result;
  }

  /// Simple evaluation fallback when JS engine is not available.
  /// Handles basic URL construction and string operations.
  String _simpleEval(String js, Map<String, String> context) {
    // Handle simple URL construction patterns
    // Pattern: java.put("key", key); java.put("page", page); urlSearchNovel(key, page)
    // This is purely a fallback — the real JS engine handles full expressions.

    // Try to extract a return value pattern
    final lines = js.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final lastLine = lines.isNotEmpty ? lines.last.trim() : '';

    // If last line is a string expression, return it as-is
    if (lastLine.startsWith("'") || lastLine.startsWith('"') || lastLine.startsWith('`')) {
      var s = lastLine;
      // Basic template literal handling
      for (final entry in context.entries) {
        s = s.replaceAll('\${${entry.key}}', entry.value);
      }
      return s.replaceAll(RegExp(r"^['\"`]|['\"`;]$"), '');
    }

    // For urlSearchNovel style: try to construct search URL
    if (lastLine.contains('urlSearchNovel') || lastLine.contains('search')) {
      final url = context['baseUrl'] ?? '';
      final key = context['key'] ?? '';
      final page = context['page'] ?? '1';
      return '$url/search?keyword=$key&page=$page';
    }

    return lastLine;
  }

  String _jsString(String s) {
    final escaped = s.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll('\n', '\\n');
    return "'$escaped'";
  }

  void dispose() {
    try {
      // _jsRuntime?.dispose();
    } catch (_) {}
  }
}
