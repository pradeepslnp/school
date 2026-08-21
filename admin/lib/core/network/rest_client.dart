import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_response.dart';

/// Supplies the current access token, or null when there is no session.
///
/// Injected rather than read from global storage inside the client. A client that reaches
/// into a storage singleton cannot be tested without that singleton, and quietly couples
/// every request to one specific auth implementation (ENGINEERING_PRINCIPLES.md §5).
typedef AccessTokenProvider = Future<String?> Function();

/// Called when the server rejects the access token.
///
/// Lets the app refresh and retry, or end the session, without the client knowing which.
typedef UnauthorizedHandler = Future<void> Function();

/// The single HTTP entry point for this console.
///
/// Every network call goes through here, so timeouts, headers, retries, and error shape are
/// decided once. A data provider that reaches for `package:http` directly bypasses all of it
/// (PROJECT_STRUCTURE.md §core/network).
///
/// Nothing here throws for a network fault — every failure becomes an
/// [ApiResponse.transportFailure], so a repository handles "the API is unreachable" on the
/// same path as "the server said no".
///
/// **No `dart:io`.** This is the one structural difference from the mobile apps' client: a
/// Flutter Web build cannot import it, so `SocketException` and `HttpHeaders` are
/// unavailable and header names are written out. `package:http` on web surfaces every
/// browser-level fault as [http.ClientException], which is caught below.
///
/// **Not a singleton.** Constructor injection, no mutable static state — so a test
/// constructs one with a fake `http.Client` and no global setup.
class RestClient {
  RestClient({
    required this.baseUrl,
    required this.clientType,
    http.Client? httpClient,
    AccessTokenProvider? accessTokenProvider,
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 2,
  })  : _http = httpClient ?? http.Client(),
        _accessToken = accessTokenProvider;

  /// Root of the API, including version — `https://host/api/v1`.
  final String baseUrl;

  /// Identifies the calling client to the server: `ADMIN_WEB`.
  final String clientType;

  /// One timeout for every verb.
  ///
  /// Generous for a desk tool on a wired connection, and deliberately not per-call: a
  /// request with no timeout is a spinner that never resolves, which on this console means
  /// an operator waiting on an alert queue that will never arrive.
  final Duration timeout;

  /// Extra attempts for methods that are safe to repeat. See [post] for why POST is not.
  final int maxRetries;

  /// Invoked on a 401 so the app can refresh the session or sign the operator out.
  final UnauthorizedHandler? onUnauthorized;

  final http.Client _http;
  final AccessTokenProvider? _accessToken;

  static const String _acceptHeader = 'accept';
  static const String _contentTypeHeader = 'content-type';
  static const String _authorizationHeader = 'authorization';
  static const String _jsonContentType = 'application/json; charset=utf-8';

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    return _send(
      'GET',
      path,
      query: query,
      extraHeaders: headers,
      // GET has no side effects, so a retry cannot duplicate anything.
      retryable: true,
    );
  }

  /// POSTs [body] as JSON.
  ///
  /// **Not retried unless [idempotencyKey] is supplied** (API_STANDARDS.md §Idempotency). A
  /// retried POST that actually succeeded the first time records the action twice. On this
  /// console that means a duplicated student import, a second guardian link, or two audit
  /// records for one operator decision — and an audit trail that disagrees with itself is
  /// worse than a failed request (BR-AUD-001).
  Future<ApiResponse> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    String? idempotencyKey,
    bool authenticated = true,
  }) {
    return _send(
      'POST',
      path,
      body: body,
      query: query,
      extraHeaders: headers,
      idempotencyKey: idempotencyKey,
      authenticated: authenticated,
      retryable: idempotencyKey != null,
    );
  }

  Future<ApiResponse> put(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    // PUT is idempotent by definition, so a retry is safe.
    return _send(
      'PUT',
      path,
      body: body,
      query: query,
      extraHeaders: headers,
      retryable: true,
    );
  }

  Future<ApiResponse> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    // PATCH is not guaranteed idempotent — a relative change applied twice differs.
    return _send(
      'PATCH',
      path,
      body: body,
      query: query,
      extraHeaders: headers,
      retryable: false,
    );
  }

  /// `DELETE` never hard-deletes in this platform; it deactivates (API_STANDARDS.md).
  Future<ApiResponse> delete(
    String path, {
    Map<String, dynamic>? query,
    Map<String, String>? headers,
  }) {
    return _send(
      'DELETE',
      path,
      query: query,
      extraHeaders: headers,
      retryable: true,
    );
  }

  void close() => _http.close();

  // --- internals ------------------------------------------------------------------------

  Future<ApiResponse> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? extraHeaders,
    String? idempotencyKey,
    bool authenticated = true,
    bool retryable = false,
  }) async {
    final uri = _uri(path, query);
    final encoded = body == null ? null : jsonEncode(body);

    final attempts = retryable ? maxRetries + 1 : 1;

    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        final headers = <String, String>{
          ...await _headers(authenticated: authenticated),
          if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
          ...?extraHeaders,
        };

        final response =
            await _dispatch(method, uri, headers, encoded).timeout(timeout);

        if (response.statusCode == 401) {
          await onUnauthorized?.call();
        }

        // 5xx is worth another attempt on a safe method; 4xx will not change.
        if (response.statusCode >= 500 && attempt < attempts - 1) {
          await _backoff(attempt);
          continue;
        }

        return _toApiResponse(response);
      } on TimeoutException {
        if (attempt < attempts - 1) {
          await _backoff(attempt);
          continue;
        }
        return const ApiResponse.transportFailure();
      } on http.ClientException {
        // On web this covers everything the browser refuses or drops: DNS failure, a
        // connection reset, and a CORS rejection alike. They are indistinguishable from
        // Dart by design — the browser withholds the detail — so they are all reported as
        // "the API could not be reached" rather than guessed at.
        if (attempt < attempts - 1) {
          await _backoff(attempt);
          continue;
        }
        return const ApiResponse.transportFailure();
      }
    }

    return const ApiResponse.transportFailure();
  }

  Future<http.Response> _dispatch(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    return switch (method) {
      'GET' => _http.get(uri, headers: headers),
      'POST' => _http.post(uri, headers: headers, body: body),
      'PUT' => _http.put(uri, headers: headers, body: body),
      'PATCH' => _http.patch(uri, headers: headers, body: body),
      'DELETE' => _http.delete(uri, headers: headers, body: body),
      _ =>
        throw ArgumentError.value(method, 'method', 'Unsupported HTTP method'),
    };
  }

  /// Exponential backoff: 200ms, 400ms, 800ms…
  Future<void> _backoff(int attempt) =>
      Future<void>.delayed(Duration(milliseconds: 200 * (1 << attempt)));

  Future<Map<String, String>> _headers({
    bool authenticated = true,
    bool json = true,
  }) async {
    final headers = <String, String>{
      _acceptHeader: 'application/json',
      'X-Client-Type': clientType,
      if (json) _contentTypeHeader: _jsonContentType,
    };

    if (authenticated) {
      final token = await _accessToken?.call();
      if (token != null && token.isNotEmpty) {
        headers[_authorizationHeader] = 'Bearer $token';
      }
    }

    return headers;
  }

  Uri _uri(String path, Map<String, dynamic>? query) {
    final normalisedPath = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse('$baseUrl$normalisedPath');

    if (query == null || query.isEmpty) return base;

    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        for (final entry in query.entries)
          if (entry.value != null) entry.key: '${entry.value}',
      },
    );
  }

  ApiResponse _toApiResponse(http.Response response) => ApiResponse(
        statusCode: response.statusCode,
        body: _decode(response.body),
        headers: response.headers,
      );

  static Map<String, Object?> _decode(String raw) {
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, Object?> ? decoded : {'data': decoded};
    } on FormatException {
      // A non-JSON body means a proxy, gateway, or CDN answered — not the API. Returning an
      // empty body lets the caller classify it as a failure rather than crashing on a parse
      // error the operator cannot act on.
      return const {};
    }
  }
}
