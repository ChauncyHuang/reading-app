class Book {
  final String id;
  final String name;
  final String author;
  final String? coverUrl;
  final String? intro;
  final String? kind;
  final String? wordCount;
  final String? lastChapter;
  final String? updateTime;
  final String? detailUrl;
  final String? tocUrl;
  final String origin; // book source name that provided this book
  final int readChapterIndex;
  final int readChapterPos;
  final bool isLocal;
  final String? localFilePath;
  final int groupId;
  final DateTime addTime;
  final DateTime lastReadTime;

  const Book({
    required this.id,
    required this.name,
    required this.author,
    this.coverUrl,
    this.intro,
    this.kind,
    this.wordCount,
    this.lastChapter,
    this.updateTime,
    this.detailUrl,
    this.tocUrl,
    required this.origin,
    this.readChapterIndex = 0,
    this.readChapterPos = 0,
    this.isLocal = false,
    this.localFilePath,
    this.groupId = 0,
    required this.addTime,
    required this.lastReadTime,
  });

  Book copyWith({
    String? id,
    String? name,
    String? author,
    String? coverUrl,
    String? intro,
    String? kind,
    String? wordCount,
    String? lastChapter,
    String? updateTime,
    String? detailUrl,
    String? tocUrl,
    String? origin,
    int? readChapterIndex,
    int? readChapterPos,
    bool? isLocal,
    String? localFilePath,
    int? groupId,
    DateTime? addTime,
    DateTime? lastReadTime,
  }) {
    return Book(
      id: id ?? this.id,
      name: name ?? this.name,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      intro: intro ?? this.intro,
      kind: kind ?? this.kind,
      wordCount: wordCount ?? this.wordCount,
      lastChapter: lastChapter ?? this.lastChapter,
      updateTime: updateTime ?? this.updateTime,
      detailUrl: detailUrl ?? this.detailUrl,
      tocUrl: tocUrl ?? this.tocUrl,
      origin: origin ?? this.origin,
      readChapterIndex: readChapterIndex ?? this.readChapterIndex,
      readChapterPos: readChapterPos ?? this.readChapterPos,
      isLocal: isLocal ?? this.isLocal,
      localFilePath: localFilePath ?? this.localFilePath,
      groupId: groupId ?? this.groupId,
      addTime: addTime ?? this.addTime,
      lastReadTime: lastReadTime ?? this.lastReadTime,
    );
  }
}
