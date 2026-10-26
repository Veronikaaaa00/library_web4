import '../models/page_result.dart';

PageResult<T> parsePage<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson, {
  required int fallbackSize,
}) {
  final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
  final items = (map['items'] as List? ?? const [])
      .whereType<Map>()
      .map((e) => fromJson(Map<String, dynamic>.from(e)))
      .toList();
  return PageResult(
    items: items,
    page: (map['page'] as num?)?.toInt() ?? 1,
    size: (map['size'] as num?)?.toInt() ?? fallbackSize,
    total: (map['total'] as num?)?.toInt() ?? items.length,
  );
}
