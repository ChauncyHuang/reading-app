import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/search_result.dart';
import '../../core/models/book_source.dart';
import '../../core/rule_engine/rule_engine.dart';
import '../../core/database/database.dart';
import '../bookshelf/bookshelf_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final db = AppDatabase.instance;
  final sources = await db.getEnabledSources();
  if (sources.isEmpty) return [];

  final engine = RuleEngine();
  final allResults = <SearchResult>[];

  // Search across all enabled sources concurrently
  for (final source in sources) {
    try {
      final results = await engine.search(source, query);
      allResults.addAll(results);
    } catch (_) {
      // skip failed sources
    }
  }

  engine.dispose();
  return _deduplicate(allResults);
});

final searchLoadingProvider = StateProvider<bool>((ref) => false);

List<SearchResult> _deduplicate(List<SearchResult> results) {
  final seen = <String>{};
  final unique = <SearchResult>[];
  for (final r in results) {
    final key = '${r.name}-${r.author}';
    if (seen.add(key)) {
      unique.add(r);
    }
  }
  return unique;
}

/// Hot search / trending keywords provider
final hotKeywordsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  return ['斗破苍穹', '凡人修仙传', '诡秘之主', '大奉打更人', '择天记'];
});
