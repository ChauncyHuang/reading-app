class Chapter {
  final String id;
  final String bookId;
  final String name;
  final String url;
  final int index;
  final bool isVip;
  final bool isPay;
  final String? content; // cached chapter text

  const Chapter({
    required this.id,
    required this.bookId,
    required this.name,
    required this.url,
    required this.index,
    this.isVip = false,
    this.isPay = false,
    this.content,
  });

  Chapter copyWith({
    String? id,
    String? bookId,
    String? name,
    String? url,
    int? index,
    bool? isVip,
    bool? isPay,
    String? content,
  }) {
    return Chapter(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      url: url ?? this.url,
      index: index ?? this.index,
      isVip: isVip ?? this.isVip,
      isPay: isPay ?? this.isPay,
      content: content ?? this.content,
    );
  }
}
