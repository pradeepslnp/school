import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_response.dart';

/// Supplies the current access token, or null when there is no session.
///
/// Injected rather than read from global storage inside the client. A client that reaches
/// into a storage singleton cannot be tested without that singleton, and quietly couples
/// every request to one specific auth implementation.
typedef AccessTokenProvider = Future<String?> Function();

/// Called when the server rejects the access token.
///
/// Lets the app refresh and retry, or end the session, without the client knowing which.
typedef UnauthorizedHandler = Future<void> Function();

/// The single HTTP entry point for this app.
///
/// Every network call goes through here, so timeouts, headers, retries, and error shape are
/// decided once. A data provider that reaches for `package:http` directly bypasses all of it.
///
/// **Not a singleton.** Constructor injection, no mutable static state
/// (ENGINEERING_PRINCIPLES.md §5) — so a test constructs one with a fake `http.Client` and
/// no global setup.
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

  /// Identifies the calling app to the server: `PARENT_APP`.
  final String clientType;

  /// One timeout for every verb.
  ///
  /// The reference implementation this replaces declared
  /// `timeOotDurationInMinutes` and then passed it to `Duration(seconds:)` in most places and
  /// `Duration(minutes:)` in one — a 60× difference that only shows up on a slow network.
  final Duration timeout;

  /// Extra attempts for methods that are safe to repeat. See [post] for why POST is not.
  final int maxRetries;

  /// Invoked on a 401 so the app can refresh the session or sign the user out.
  final UnauthorizedHandler? onUnauthorized;

  final http.Client _http;
  final AccessTokenProvider? _accessToken;

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
  /// **Not retried unless [idempotencyKey] is supplied.** A retried POST that actually
  /// succeeded the first time records the action twice — for a boarding or handover event
  /// that means a child appears to board a bus twice, and the reconciliation at trip close
  /// is wrong. With a key, the server deduplicates and retrying is safe (BR-BOARD-*).
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

  /// Uploads [fileBytes] as a multipart request — incident photos, bulk imports.
  Future<ApiResponse> postMultipart(
    String path, {
    required String fieldName,
    required List<int> fileBytes,
    required String filename,
    required MediaType contentType,
    Map<String, String>? fields,
    Map<String, dynamic>? query,
    Duration? uploadTimeout,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri(path, query))
        ..headers.addAll(await _headers(json: false))
        ..fields.addAll(fields ?? const {})
        ..files.add(
          http.MultipartFile.fromBytes(
            fieldName,
            fileBytes,
            filename: filename,
            contentType: contentType,
          ),
        );

      final streamed = await _http
          .send(request)
          // Uploads run over the same mobile connections as everything else but move far
          // more data, so they get their own, longer budget.
          .timeout(uploadTimeout ?? const Duration(minutes: 2));

      final response = await http.Response.fromStream(streamed);
      return _toApiResponse(response);
    } on Object {
      return const ApiResponse.transportFailure();
    }
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
          'Idempotency-Key': ?idempotencyKey,
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
      } on SocketException {
        if (attempt < attempts - 1) {
          await _backoff(attempt);
          continue;
        }
        return const ApiResponse.transportFailure();
      } on TimeoutException {
        if (attempt < attempts - 1) {
          await _backoff(attempt);
          continue;
        }
        return const ApiResponse.transportFailure();
      } on http.ClientException {
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
      _ => throw ArgumentError.value(method, 'method', 'Unsupported HTTP method'),
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
      HttpHeaders.acceptHeader: 'application/json',
      'X-Client-Type': clientType,
      if (json) HttpHeaders.contentTypeHeader: 'application/json',
    };

    if (authenticated) {
      final token = await _accessToken?.call();
      if (token != null && token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
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
      );

  static Map<String, Object?> _decode(String raw) {
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, Object?> ? decoded : {'data': decoded};
    } on FormatException {
      // A non-JSON body means a proxy or gateway answered, not the API. Returning an empty
      // body lets the caller classify it as a failure rather than crashing on a parse error
      // the user cannot act on.
      return const {};
    }
  }
}
