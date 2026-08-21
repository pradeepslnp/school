/// A decoded HTTP response, before interpretation.
///
/// Deliberately not `dynamic`. A client returning `dynamic` pushes every null check and cast
/// into the callers, and the compiler stops helping at exactly the layer where a malformed
/// response is most likely.
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.body,
    this.isTransportFailure = false,
  });

  /// The request never reached the server, or no usable reply came back.
  ///
  /// Modelled as a response rather than thrown, so a data provider handles "no network" on
  /// the same path as "server said no" instead of wrapping every call in a try/catch.
  const ApiResponse.transportFailure()
      : statusCode = 0,
        body = const {},
        isTransportFailure = true;

  final int statusCode;
  final Map<String, Object?> body;
  final bool isTransportFailure;

  bool get isSuccess =>
      !isTransportFailure && statusCode >= 200 && statusCode < 300;

  /// True when the access token is missing, expired, or revoked.
  bool get isUnauthorized => statusCode == 401;

  /// True when the server refused because of throttling.
  bool get isRateLimited => statusCode == 429;

  /// Payload under the standard `data` envelope (docs/04-api/API_STANDARDS.md).
  Map<String, Object?> get data =>
      body['data'] as Map<String, Object?>? ?? const {};

  /// A `data` payload that is a list rather than an object.
  List<Object?> get dataList => body['data'] as List<Object?>? ?? const [];

  /// Machine-readable error code under the standard `error` envelope.
  String? get errorCode {
    final error = body['error'] as Map<String, Object?>?;
    return error?['code'] as String?;
  }

  /// Localisation key for the error.
  ///
  /// The UI renders from this, never from a server-supplied display string (BR-CFG-005) —
  /// the server does not know the guardian's language.
  String? get errorMessageKey {
    final error = body['error'] as Map<String, Object?>?;
    return error?['messageKey'] as String?;
  }

  /// Per-field validation failures, keyed by field name.
  Map<String, Object?> get fieldErrors {
    final error = body['error'] as Map<String, Object?>?;
    return error?['fields'] as Map<String, Object?>? ?? const {};
  }

  @override
  String toString() => isTransportFailure
      ? 'ApiResponse(transport failure)'
      : 'ApiResponse($statusCode, error: $errorCode)';
}
