import '../network/json_parser.dart';

class PaginatedResult<T> {
  PaginatedResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.hasMore,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;

  factory PaginatedResult.fromBody(
    dynamic body,
    T Function(Map<String, dynamic>) mapper,
  ) {
    final items = extractListMap(body).map(mapper).toList();
    final meta = extractPagination(normalizeApiBody(body));
    return PaginatedResult<T>(
      items: items,
      currentPage: meta?.currentPage ?? 1,
      lastPage: meta?.lastPage ?? 1,
      total: meta?.total ?? items.length,
      hasMore: meta?.hasMore ?? false,
    );
  }
}
