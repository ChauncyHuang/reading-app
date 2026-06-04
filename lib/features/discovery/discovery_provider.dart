import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/search_result.dart';
import '../../core/models/book_source.dart';
import '../../core/rule_engine/rule_engine.dart';
import '../../core/database/database.dart';

/// Discovery state for a source.
final discoveryProvider = FutureProvider.autoDispose.family<List<SearchResult>, int>((ref, sourceIndex) async {
  final db = AppDatabase.instance;
  final sources = await db.getEnabledSources();
  if (sourceIndex >= sources.length) return [];

  final source = sources[sourceIndex];
  final engine = RuleEngine();

  // Common explore paths for Chinese novel sites
  final exploreUrls = <String>[];
  if (source.ruleExplore != null) {
    exploreUrls.add('');
  }

  final allResults = <SearchResult>[];
  for (final url in exploreUrls) {
    try {
      final results = await engine.discover(source, url);
      allResults.addAll(results);
    } catch (_) {}
  }

  engine.dispose();
  return allResults;
});

/// Provider that resolves a source's explore sections.
/// Each section is a tab/category in the discovery view.
final exploreSectionsProvider = FutureProvider.autoDispose<List<ExploreSection>>((ref) async {
  final db = AppDatabase.instance;
  final sources = await db.getEnabledSources();

  final sections = <ExploreSection>[];
  for (final source in sources) {
    // Parse exploreUrl if it contains multiple sections (JSON array)
    if (source.ruleExplore != null) {
      sections.add(ExploreSection(
        title: source.bookSourceName,
        sourceIndex: sections.length,
        source: source,
      ));
    }
  }
  return sections;
});

class ExploreSection {
  final String title;
  final int sourceIndex;
  final BookSource source;

  const ExploreSection({required this.title, required this.sourceIndex, required this.source});
}
