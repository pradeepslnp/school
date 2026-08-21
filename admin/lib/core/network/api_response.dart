/// A decoded HTTP response, before interpretation.
///
/// Deliberately not `dynamic`. A client returning `dynamic` pushes every null check and cast
/// into the callers, and the compiler stops helping at exactly the layer where a malformed
/// response is most likely.
///
/// Envelope shapes follow [`API_STANDARDS.md`] §Standard Response Envelope.
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
    this.isTransportFailure = false,
  });

  /// The request never reached the server, or no usable reply came back.
  ///
  /// Modelled as a response rather than thrown, so a data provider handles "the API is
  /// unreachable" on the same path as "the server said no" instead of wrapping every call
  /// in a try/catch.
  const ApiResponse.transportFailure()
      : statusCode = 0,
        body = const {},
        headers = const {},
        isTransportFailure = true;

  final int statusCode;
  final Map<String, Object?> body;

  /// Response headers, lowercased by `package:http`.
  final Map<String, String> headers;

  final bool isTransportFailure;

  bool get isSuccess =>
      !isTransportFailure && statusCode >= 200 && statusCode < 300;

  /// True when the access token is missing, expired, or revoked.
  bool get isUnauthorized => statusCode == 401;

  /// True when the server refused because of throttling.
  ///
  /// The sign-in endpoints are the most heavily rate-limited in the platform
  /// (AUTHENTICATION_API.md), so this is an ordinary outcome on the console's first screen,
  /// not an edge case.
  bool get isRateLimited => statusCode == 429;

  /// Payload under the standard `data` envelope.
  Map<String, Object?> get data =>
      body['data'] as Map<String, Object?>? ?? const {};

  /// A `data` payload that is a list rather than an object — every collection endpoint.
  List<Object?> get dataList => body['data'] as List<Object?>? ?? const [];

  /// Cursor for the next page, from `meta.pagination` (API_STANDARDS.md §Pagination).
  ///
  /// Null when this is the last page, and null on an endpoint that does not page at all — a
  /// caller that asks and gets null has simply reached the end either way.
  ///
  /// Deliberately opaque: the console passes this value straight back rather than deriving the
  /// next position from the rows it received. The server can change what the cursor encodes
  /// without a client release, which is the point of returning one instead of an offset.
  String? get nextCursor {
    final meta = body['meta'];
    if (meta is! Map<String, Object?>) return null;
    final pagination = meta['pagination'];
    if (pagination is! Map<String, Object?>) return null;
    return pagination['nextCursor'] as String?;
  }

  /// Machine-readable error code under the standard `error` envelope.
  String? get errorCode => _error?['code'] as String?;

  /// Localisation key for the error.
  ///
  /// The UI renders from this, never from a server-supplied display string (BR-CFG-005).
  String? get errorMessageKey => _error?['messageKey'] as String?;

  /// The business rule that refused the operation, e.g. `BR-GRD-002`.
  String? get errorBusinessRule => _error?['businessRule'] as String?;

  /// Per-field failures from a `400`, in the documented `details[]` shape:
  /// `[{ "field": "…", "issue": "…" }]`.
  ///
  /// Returned as a list rather than collapsed into a map because the contract permits
  /// several issues against one field, and a map would silently keep only the last.
  List<Map<String, Object?>> get errorDetails {
    final details = _error?['details'];
    if (details is! List) return const [];
    return details.whereType<Map<String, Object?>>().toList(growable: false);
  }

  Map<String, Object?>? get _error => body['error'] as Map<String, Object?>?;

  @override
  String toString() => isTransportFailure
      ? 'ApiResponse(transport failure)'
      : 'ApiResponse($statusCode, error: $errorCode)';
}
