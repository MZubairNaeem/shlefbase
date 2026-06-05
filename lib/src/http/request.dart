import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

/// A rich, Laravel-inspired HTTP request wrapper.
///
/// Wraps the raw Shelf [shelf.Request] and adds convenient accessors for
/// path params, query string, headers, and body parsing.
///
/// The body is read lazily and cached — calling [body] or [json] multiple
/// times within the same request is safe.
class Request {
  final shelf.Request _inner;
  final Map<String, String> _params;

  String? _cachedBody;

  Request(this._inner, {Map<String, String> params = const {}})
      : _params = params;

  // ── Method & URL ──────────────────────────────────────────────────────────

  /// HTTP verb in UPPER case (e.g. `'GET'`).
  String get method => _inner.method.toUpperCase();

  /// URL path, without query string (e.g. `'/users/42'`).
  String get path => _inner.requestedUri.path;

  /// Full URI including query string.
  Uri get uri => _inner.requestedUri;

  /// Whether the request carries a JSON content-type header.
  bool get isJson {
    final ct = header('content-type') ?? '';
    return ct.contains('application/json');
  }

  // ── Route params ─────────────────────────────────────────────────────────

  /// Returns the route parameter named [key] (e.g. `'id'` from `/<id>`).
  ///
  /// Returns an empty string if [key] is not in the route pattern.
  String param(String key) => _params[key] ?? '';

  /// All route parameters extracted from the URL pattern.
  Map<String, String> get params => Map.unmodifiable(_params);

  // ── Query string ─────────────────────────────────────────────────────────

  /// Returns the query string value for [key], or `null` if absent.
  ///
  /// ```dart
  /// // GET /users?page=2&limit=10
  /// request.query('page');  // → '2'
  /// ```
  String? query(String key) => _inner.requestedUri.queryParameters[key];

  /// All query string parameters.
  Map<String, String> get queryAll => _inner.requestedUri.queryParameters;

  // ── Headers ───────────────────────────────────────────────────────────────

  /// Returns the header value for [name] (case-insensitive), or `null`.
  String? header(String name) => _inner.headers[name.toLowerCase()];

  /// All request headers.
  Map<String, String> get headers => _inner.headers;

  /// The value of the `Authorization` header, or `null`.
  String? get authorization => header('authorization');

  /// Bearer token from `Authorization: Bearer <token>`, or `null`.
  String? get bearerToken {
    final auth = authorization;
    if (auth == null || !auth.startsWith('Bearer ')) return null;
    return auth.substring(7);
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  /// Reads and returns the raw request body as a UTF-8 string.
  ///
  /// The result is cached — subsequent calls return the same string without
  /// re-reading the underlying stream.
  Future<String> body() async => _cachedBody ??= await _inner.readAsString();

  /// Parses the request body as JSON and returns the decoded value.
  ///
  /// Throws [FormatException] if the body is not valid JSON.
  Future<dynamic> json() async => jsonDecode(await body());

  /// Parses the request body as a JSON object.
  ///
  /// Throws [FormatException] if the body is not a JSON object.
  Future<Map<String, dynamic>> jsonMap() async =>
      await json() as Map<String, dynamic>;

  /// Returns the value for [key] from the parsed JSON body, or `null`.
  Future<dynamic> input(String key) async {
    final data = await jsonMap();
    return data[key];
  }

  /// Parses the URL-encoded form body and returns all fields.
  Future<Map<String, String>> form() async {
    final raw = await body();
    return Uri.splitQueryString(raw);
  }

  // ── Connection ───────────────────────────────────────────────────────────

  /// Best-effort client IP address.
  String? get ip {
    return header('x-forwarded-for')?.split(',').first.trim() ??
        header('x-real-ip');
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  /// The underlying Shelf request. Prefer this framework's API over accessing
  /// the inner request directly.
  shelf.Request get inner => _inner;
}
