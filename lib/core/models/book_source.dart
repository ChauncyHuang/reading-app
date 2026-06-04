import 'dart:convert';

/// Legado-compatible book source model.
class BookSource {
  final String bookSourceName;
  final String bookSourceUrl;
  final String? bookSourceGroup;
  final String? bookSourceComment;
  final int bookSourceType; // 0=text, 1=audio, 2=image
  final bool enabled;
  final int customOrder;
  final int weight;
  final String? header;
  final bool enabledCookieJar;
  final String? concurrentRate;
  final String? loginUrl;
  final String? loginCheckJs;
  final String? bookUrlPattern;
  final String? searchUrl;
  final RuleSearch? ruleSearch;
  final RuleExplore? ruleExplore;
  final RuleBookInfo? ruleBookInfo;
  final RuleToc? ruleToc;
  final RuleContent? ruleContent;

  const BookSource({
    required this.bookSourceName,
    required this.bookSourceUrl,
    this.bookSourceGroup,
    this.bookSourceComment,
    this.bookSourceType = 0,
    this.enabled = true,
    this.customOrder = 0,
    this.weight = 0,
    this.header,
    this.enabledCookieJar = true,
    this.concurrentRate,
    this.loginUrl,
    this.loginCheckJs,
    this.bookUrlPattern,
    this.searchUrl,
    this.ruleSearch,
    this.ruleExplore,
    this.ruleBookInfo,
    this.ruleToc,
    this.ruleContent,
  });

  factory BookSource.fromJson(Map<String, dynamic> json) {
    return BookSource(
      bookSourceName: json['bookSourceName'] as String? ?? '',
      bookSourceUrl: json['bookSourceUrl'] as String? ?? '',
      bookSourceGroup: json['bookSourceGroup'] as String?,
      bookSourceComment: json['bookSourceComment'] as String?,
      bookSourceType: json['bookSourceType'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
      customOrder: json['customOrder'] as int? ?? 0,
      weight: json['weight'] as int? ?? 0,
      header: json['header'] as String?,
      enabledCookieJar: json['enabledCookieJar'] as bool? ?? true,
      concurrentRate: json['concurrentRate'] as String?,
      loginUrl: json['loginUrl'] as String?,
      loginCheckJs: json['loginCheckJs'] as String?,
      bookUrlPattern: json['bookUrlPattern'] as String?,
      searchUrl: json['searchUrl'] as String?,
      ruleSearch: json['ruleSearch'] != null
          ? RuleSearch.fromJson(json['ruleSearch'] as Map<String, dynamic>)
          : null,
      ruleExplore: json['ruleExplore'] != null
          ? RuleExplore.fromJson(json['ruleExplore'] as Map<String, dynamic>)
          : null,
      ruleBookInfo: json['ruleBookInfo'] != null
          ? RuleBookInfo.fromJson(json['ruleBookInfo'] as Map<String, dynamic>)
          : null,
      ruleToc: json['ruleToc'] != null
          ? RuleToc.fromJson(json['ruleToc'] as Map<String, dynamic>)
          : null,
      ruleContent: json['ruleContent'] != null
          ? RuleContent.fromJson(json['ruleContent'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookSourceName': bookSourceName,
      'bookSourceUrl': bookSourceUrl,
      if (bookSourceGroup != null) 'bookSourceGroup': bookSourceGroup,
      if (bookSourceComment != null) 'bookSourceComment': bookSourceComment,
      'bookSourceType': bookSourceType,
      'enabled': enabled,
      'customOrder': customOrder,
      'weight': weight,
      if (header != null) 'header': header,
      'enabledCookieJar': enabledCookieJar,
      if (concurrentRate != null) 'concurrentRate': concurrentRate,
      if (loginUrl != null) 'loginUrl': loginUrl,
      if (loginCheckJs != null) 'loginCheckJs': loginCheckJs,
      if (bookUrlPattern != null) 'bookUrlPattern': bookUrlPattern,
      if (searchUrl != null) 'searchUrl': searchUrl,
      if (ruleSearch != null) 'ruleSearch': ruleSearch!.toJson(),
      if (ruleExplore != null) 'ruleExplore': ruleExplore!.toJson(),
      if (ruleBookInfo != null) 'ruleBookInfo': ruleBookInfo!.toJson(),
      if (ruleToc != null) 'ruleToc': ruleToc!.toJson(),
      if (ruleContent != null) 'ruleContent': ruleContent!.toJson(),
    };
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class RuleSearch {
  final String? bookList;
  final String? name;
  final String? author;
  final String? kind;
  final String? wordCount;
  final String? lastChapter;
  final String? updateTime;
  final String? coverUrl;
  final String? detailUrl;
  final String? intro;

  const RuleSearch({
    this.bookList,
    this.name,
    this.author,
    this.kind,
    this.wordCount,
    this.lastChapter,
    this.updateTime,
    this.coverUrl,
    this.detailUrl,
    this.intro,
  });

  factory RuleSearch.fromJson(Map<String, dynamic> json) {
    return RuleSearch(
      bookList: json['bookList'] as String?,
      name: json['name'] as String?,
      author: json['author'] as String?,
      kind: json['kind'] as String?,
      wordCount: json['wordCount'] as String?,
      lastChapter: json['lastChapter'] as String?,
      updateTime: json['updateTime'] as String?,
      coverUrl: json['coverUrl'] as String?,
      detailUrl: json['detailUrl'] as String?,
      intro: json['intro'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bookList != null) 'bookList': bookList,
      if (name != null) 'name': name,
      if (author != null) 'author': author,
      if (kind != null) 'kind': kind,
      if (wordCount != null) 'wordCount': wordCount,
      if (lastChapter != null) 'lastChapter': lastChapter,
      if (updateTime != null) 'updateTime': updateTime,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (detailUrl != null) 'detailUrl': detailUrl,
      if (intro != null) 'intro': intro,
    };
  }
}

class RuleExplore {
  final String? bookList;
  final String? name;
  final String? author;
  final String? kind;
  final String? wordCount;
  final String? lastChapter;
  final String? coverUrl;
  final String? detailUrl;

  const RuleExplore({
    this.bookList,
    this.name,
    this.author,
    this.kind,
    this.wordCount,
    this.lastChapter,
    this.coverUrl,
    this.detailUrl,
  });

  factory RuleExplore.fromJson(Map<String, dynamic> json) {
    return RuleExplore(
      bookList: json['bookList'] as String?,
      name: json['name'] as String?,
      author: json['author'] as String?,
      kind: json['kind'] as String?,
      wordCount: json['wordCount'] as String?,
      lastChapter: json['lastChapter'] as String?,
      coverUrl: json['coverUrl'] as String?,
      detailUrl: json['detailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (bookList != null) 'bookList': bookList,
      if (name != null) 'name': name,
      if (author != null) 'author': author,
      if (kind != null) 'kind': kind,
      if (wordCount != null) 'wordCount': wordCount,
      if (lastChapter != null) 'lastChapter': lastChapter,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (detailUrl != null) 'detailUrl': detailUrl,
    };
  }
}

class RuleBookInfo {
  final String? init;
  final String? name;
  final String? author;
  final String? coverUrl;
  final String? intro;
  final String? kind;
  final String? wordCount;
  final String? lastChapter;
  final String? updateTime;
  final String? tocUrl;
  final bool? canReName;

  const RuleBookInfo({
    this.init,
    this.name,
    this.author,
    this.coverUrl,
    this.intro,
    this.kind,
    this.wordCount,
    this.lastChapter,
    this.updateTime,
    this.tocUrl,
    this.canReName,
  });

  factory RuleBookInfo.fromJson(Map<String, dynamic> json) {
    return RuleBookInfo(
      init: json['init'] as String?,
      name: json['name'] as String?,
      author: json['author'] as String?,
      coverUrl: json['coverUrl'] as String?,
      intro: json['intro'] as String?,
      kind: json['kind'] as String?,
      wordCount: json['wordCount'] as String?,
      lastChapter: json['lastChapter'] as String?,
      updateTime: json['updateTime'] as String?,
      tocUrl: json['tocUrl'] as String?,
      canReName: json['canReName'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (init != null) 'init': init,
      if (name != null) 'name': name,
      if (author != null) 'author': author,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (intro != null) 'intro': intro,
      if (kind != null) 'kind': kind,
      if (wordCount != null) 'wordCount': wordCount,
      if (lastChapter != null) 'lastChapter': lastChapter,
      if (updateTime != null) 'updateTime': updateTime,
      if (tocUrl != null) 'tocUrl': tocUrl,
      if (canReName != null) 'canReName': canReName,
    };
  }
}

class RuleToc {
  final String? chapterList;
  final String? chapterName;
  final String? chapterUrl;
  final bool? isVip;
  final bool? isPay;
  final String? updateTime;
  final String? nextTocUrl;

  const RuleToc({
    this.chapterList,
    this.chapterName,
    this.chapterUrl,
    this.isVip,
    this.isPay,
    this.updateTime,
    this.nextTocUrl,
  });

  factory RuleToc.fromJson(Map<String, dynamic> json) {
    return RuleToc(
      chapterList: json['chapterList'] as String?,
      chapterName: json['chapterName'] as String?,
      chapterUrl: json['chapterUrl'] as String?,
      isVip: json['isVip'] as bool?,
      isPay: json['isPay'] as bool?,
      updateTime: json['updateTime'] as String?,
      nextTocUrl: json['nextTocUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (chapterList != null) 'chapterList': chapterList,
      if (chapterName != null) 'chapterName': chapterName,
      if (chapterUrl != null) 'chapterUrl': chapterUrl,
      if (isVip != null) 'isVip': isVip,
      if (isPay != null) 'isPay': isPay,
      if (updateTime != null) 'updateTime': updateTime,
      if (nextTocUrl != null) 'nextTocUrl': nextTocUrl,
    };
  }
}

class RuleContent {
  final String? content;
  final String? replaceRegex;
  final String? imageStyle;
  final String? webJs;
  final String? sourceRegex;
  final String? nextContentUrl;

  const RuleContent({
    this.content,
    this.replaceRegex,
    this.imageStyle,
    this.webJs,
    this.sourceRegex,
    this.nextContentUrl,
  });

  factory RuleContent.fromJson(Map<String, dynamic> json) {
    return RuleContent(
      content: json['content'] as String?,
      replaceRegex: json['replaceRegex'] as String?,
      imageStyle: json['imageStyle'] as String?,
      webJs: json['webJs'] as String?,
      sourceRegex: json['sourceRegex'] as String?,
      nextContentUrl: json['nextContentUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (content != null) 'content': content,
      if (replaceRegex != null) 'replaceRegex': replaceRegex,
      if (imageStyle != null) 'imageStyle': imageStyle,
      if (webJs != null) 'webJs': webJs,
      if (sourceRegex != null) 'sourceRegex': sourceRegex,
      if (nextContentUrl != null) 'nextContentUrl': nextContentUrl,
    };
  }
}
