/// A decoded HTTP response, before interpretation.
///
/// Deliberately not `dynamic`. A client returning `dynamic` pushes every null check and cast
/// into the callers, and the compiler stops helping at exactly the layer where a malformed
/// response is most likely.
class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.body,
    this.headers = const {},
    this.sentAt,
    this.receivedAt,
    this.isTransportFailure = false,
  });

  /// The request never reached the server, or no usable reply came back.
  ///
  /// Modelled as a response rather than thrown, so a data provider handles "no network" on
  /// the same path as "server said no" instead of wrapping every call in a try/catch.
  const ApiResponse.transportFailure()
      : statusCode = 0,
        body = const {},
        headers = const {},
        sentAt = null,
        receivedAt = null,
        isTransportFailure = true;

  final int statusCode;
  final Map<String, Object?> body;

  /// Response headers, lowercased by `package:http`.
  ///
  /// Carried because the `Date` header is this app's source of server time. ADR-0008
  /// requires the device-vs-server clock skew to be measured on each sync, and every sync
  /// already makes a request — so the measurement rides along on replies the app was
  /// making anyway, rather than costing an extra round trip from a vehicle
  /// (core/time/clock_skew.dart).
  final Map<String, String> headers;

  /// Device-clock readings either side of the attempt that produced this response.
  ///
  /// Of the final attempt only: [RestClient] may retry internally, and a window spanning
  /// several attempts plus backoff would make the skew estimate useless. Null on a
  /// transport failure, where there is no exchange to time.
  final DateTime? sentAt;
  final DateTime? receivedAt;

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
