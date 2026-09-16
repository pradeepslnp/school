import '../../../core/domain.dart';
import '../../../core/network/api_response.dart';
import '../data_provider/search_data_provider.dart';
import '../domain/search_models.dart';

/// Turns search transport into domain outcomes.
///
/// The bloc depends on this, never on [SearchDataProvider] directly — matching `VehicleRepository`.
///
/// **No Flutter imports** (CODING_STANDARDS_FLUTTER.md §Layering).
class SearchRepository {
  SearchRepository({required this.dataProvider});

  final SearchDataProvider dataProvider;

  Future<Result<SearchResults>> search({required String query}) async {
    final response = await dataProvider.search(query: query);
    if (!response.isSuccess) return _toFailure<SearchResults>(response);

    final data = response.data;
    final groups = (data['groups'] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(_parseGroup)
        .whereType<SearchGroup>()
        .toList(growable: false);

    return Success<SearchResults>(
      SearchResults(query: _string(data['query']) ?? query, groups: groups),
    );
  }

  Result<T> _toFailure<T>(ApiResponse response) {
    if (response.isTransportFailure) {
      return Failure<T>(ErrorCode.dependencyUnavailable);
    }
    return Failure<T>(
      ErrorCode.fromWire(response.errorCode),
      messageKey: response.errorMessageKey,
      businessRule: response.errorBusinessRule,
    );
  }

  /// A kind this build does not know is dropped: it could be neither labelled nor opened.
  SearchGroup? _parseGroup(Map<String, Object?> json) {
    final type = SearchResultType.fromWire(json['type']);
    if (type == SearchResultType.unknown) return null;

    final hits = (json['results'] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map((hit) => _parseHit(type, hit))
        .whereType<SearchHit>()
        .toList(growable: false);
    if (hits.isEmpty) return null;

    return SearchGroup(type: type, hits: hits, hasMore: json['hasMore'] == true);
  }

  SearchHit? _parseHit(SearchResultType type, Map<String, Object?> json) {
    final id = _string(json['id']);
    final title = _string(json['title']);
    if (id == null || title == null) return null;

    return SearchHit(
      type: type,
      id: id,
      title: title,
      matchedField: SearchMatchedField.fromWire(json['matchedField']),
      matchedValue: _string(json['matchedValue']) ?? title,
      kind: _string(json['kind']),
      code: _string(json['code']),
      status: _string(json['status']),
      schoolId: _string(json['schoolId']),
      schoolName: _string(json['schoolName']),
      relatedStudentId: _string(json['relatedStudentId']),
      relatedStudentName: _string(json['relatedStudentName']),
      organizationId: _string(json['organizationId']),
      organizationName: _string(json['organizationName']),
    );
  }

  static String? _string(Object? value) => value is String ? value : null;
}
