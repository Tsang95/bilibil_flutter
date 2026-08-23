final class PagedResult<T> {
  const PagedResult({
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.isLastPage,
    required this.items,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) parser,
  ) {
    final rawItems = json['list'] ?? json['items'] ?? json['rows'];
    final page = _integer(json['page']);
    final totalPages = _integer(
      json['totalPage'] ?? json['total_page'] ?? json['last_page'],
    );
    final explicitLastPage = json['is_last'] ?? json['isLast'];
    return PagedResult<T>(
      page: page,
      totalPages: totalPages,
      totalItems: _integer(
        json['totalSize'] ?? json['total_size'] ?? json['total'],
      ),
      isLastPage: explicitLastPage is bool
          ? explicitLastPage
          : explicitLastPage is num
          ? explicitLastPage == 1
          : explicitLastPage is String
          ? explicitLastPage.toLowerCase() == 'true' || explicitLastPage == '1'
          : totalPages > 0 && page >= totalPages,
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((item) => parser(Map<String, dynamic>.from(item)))
                .toList(growable: false)
          : <T>[],
    );
  }

  final int page;
  final int totalPages;
  final int totalItems;
  final bool isLastPage;
  final List<T> items;

  bool get hasMore => !isLastPage && (totalPages == 0 || page < totalPages);

  static int _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
