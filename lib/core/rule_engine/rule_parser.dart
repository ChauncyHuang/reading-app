import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

class RuleParser {
  /// Parse an HTML string into a DOM document.
  html_dom.Document parseHtml(String html) => html_parser.parse(html);

  /// Evaluate a rule against an HTML string.
  /// Rules can be:
  /// - CSS selector: "div.book-list > a"
  /// - JSONPath-like: "$.data.list[*]"
  /// - XPath-like: "//div[@class='book']"
  /// - Direct attribute: "div.book@href" (select first, get attribute)
  /// - Text content: "div.title@text"
  String? evaluate(String html, String? rule) {
    if (rule == null || rule.isEmpty) return null;
    final doc = parseHtml(html);

    if (rule.startsWith(r'$.')) {
      return _evalJsonPath(html, rule);
    }
    if (rule.startsWith('//')) {
      return _evalXPath(doc, rule);
    }

    // CSS selector rule
    if (rule.contains('@')) {
      final parts = rule.split('@');
      final selector = parts[0];
      final attr = parts.length > 1 ? parts[1] : null;
      final elements = doc.querySelectorAll(selector);
      if (elements.isEmpty) return null;
      if (attr == 'text') return elements.first.text.trim();
      if (attr == 'html') return elements.first.innerHtml;
      if (attr == 'ownText') {
        // Remove child element text, keep only direct text
        return elements.first.nodes
            .whereType<html_dom.Text>()
            .map((t) => t.text)
            .join()
            .trim();
      }
      return elements.first.attributes[attr];
    }

    // Simple CSS selector
    final elements = doc.querySelectorAll(rule);
    if (elements.isEmpty) return null;
    if (elements.length == 1) return elements.first.text.trim();
    return null;
  }

  /// Evaluate a rule against a list of elements.
  List<html_dom.Element> selectElements(String html, String? rule) {
    if (rule == null || rule.isEmpty) return [];
    final doc = parseHtml(html);

    if (rule.startsWith(r'$.')) {
      return []; // JSON path handled separately
    }

    return doc.querySelectorAll(rule).toList();
  }

  /// Evaluate multiple rules and return a map of results.
  Map<String, String?> evaluateAll(String html, Map<String, String?> rules) {
    final results = <String, String?>{};
    for (final entry in rules.entries) {
      results[entry.key] = evaluate(html, entry.value);
    }
    return results;
  }

  /// Parse a single element using rules map.
  Map<String, String?> parseElement(html_dom.Element element, Map<String, String?> rules) {
    final results = <String, String?>{};
    final elementHtml = element.outerHtml;
    for (final entry in rules.entries) {
      if (entry.value == null) {
        results[entry.key] = null;
        continue;
      }
      results[entry.key] = evaluateOnElement(element, entry.value!);
    }
    return results;
  }

  /// Evaluate a rule on a specific element.
  String? evaluateOnElement(html_dom.Element element, String rule) {
    if (rule.contains('@')) {
      final parts = rule.split('@');
      final attr = parts.length > 1 ? parts[1] : null;
      if (attr == 'text') return element.text.trim();
      if (attr == 'html') return element.innerHtml;
      if (attr == 'ownText') {
        return element.nodes
            .whereType<html_dom.Text>()
            .map((t) => t.text)
            .join()
            .trim();
      }
      return element.attributes[attr];
    }
    // Treat as CSS selector within the element
    final child = element.querySelector(rule);
    return child?.text.trim();
  }

  /// Extract text content using rule, with optional regex replacement.
  String? extractContent(String html, String? rule, String? replaceRegex) {
    if (rule == null) return null;
    var content = evaluate(html, rule);

    if (content != null && replaceRegex != null && replaceRegex.isNotEmpty) {
      // Parse replacement patterns like "##regex##replacement##"
      final patterns = RegExp(r'##(.*?)##(.*?)##');
      content = content.replaceAllMapped(patterns, (match) {
        final regex = RegExp(match.group(1)!);
        final replacement = match.group(2) ?? '';
        return content!.replaceAll(regex, replacement);
      });
    }

    return content;
  }

  /// Simple JSONPath evaluation.
  String? _evalJsonPath(String jsonStr, String rule) {
    try {
      final doc = html_parser.parse(jsonStr);
      final text = doc.body?.text ?? jsonStr;
      // Remove leading $. and parse
      final path = rule.substring(2);
      // Simple implementation: return the raw text and let caller handle JSON parsing
      return text;
    } catch (_) {
      return null;
    }
  }

  /// Simple XPath-like evaluation (CSS fallback).
  String? _evalXPath(html_dom.Document doc, String rule) {
    try {
      // Convert simple XPath to CSS
      final css = rule
          .replaceAll(RegExp(r"//(\w+)\[@class='(\w+)'\]"), r'$1.$2')
          .replaceAll(RegExp(r"//(\w+)\[@id='(\w+)'\]"), r'$1#$2')
          .replaceAll('//', ' ')
          .replaceAll('/', ' > ');
      final elements = doc.querySelectorAll(css);
      if (elements.isEmpty) return null;
      return elements.first.text.trim();
    } catch (_) {
      return null;
    }
  }
}
