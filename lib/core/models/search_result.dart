class SearchResult {
  final String name;
  final String author;
  final String? coverUrl;
  final String? detailUrl;
  final String? kind;
  final String? wordCount;
  final String? lastChapter;
  final String? intro;
  final String sourceName;
  final String sourceUrl;

  const SearchResult({
    required this.name,
    required this.author,
    this.coverUrl,
    this.detailUrl,
    this.kind,
    this.wordCount,
    this.lastChapter,
    this.intro,
    required this.sourceName,
    required this.sourceUrl,
  });
}

class DiscoveryItem {
  final String title;
  final String url;
  final String? coverUrl;
  final String? author;
  final String? kind;

  const DiscoveryItem({
    required this.title,
    required this.url,
    this.coverUrl,
    this.author,
    this.kind,
  });
}

class DiscoveryCategory {
  final String name;
  final String url;
  final List<DiscoveryItem> items;

  const DiscoveryCategory({
    required this.name,
    required this.url,
    this.items = const [],
  });
}
