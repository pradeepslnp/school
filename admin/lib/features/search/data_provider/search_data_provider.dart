import '../../../core/network/api_response.dart';
import '../../../core/network/rest_client.dart';

/// Transport for global search (SRC-001).
///
/// Calls [RestClient] rather than `package:http` directly, matching every other data provider in
/// this console. This layer speaks the endpoint and JSON only; what a failure means is
/// `SearchRepository`'s job.
///
/// Contract: [`SEARCH_API.md`].
class SearchDataProvider {
  SearchDataProvider({required this.client});

  final RestClient client;

  /// `GET /search?q=` (`PERM-SEARCH-QUERY`).
  ///
  /// No organization is named: what a search spans is decided server-side from the caller's scope
  /// — their own organization, or every organization for a platform operator (ADR-0018).
  Future<ApiResponse> search({required String query}) {
    return client.get('/search', query: {'q': query});
  }
}
