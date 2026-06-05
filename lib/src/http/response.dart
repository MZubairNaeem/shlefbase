import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

const _jsonContentType = 'application/json; charset=utf-8';
const _textContentType = 'text/plain; charset=utf-8';
const _htmlContentType = 'text/html; charset=utf-8';

/// An immutable HTTP response value object.
///
/// Create responses through the static factory methods:
///
/// ```dart
/// return Response.json({'users': users});
/// return Response.created({'id': newId});
/// return Response.notFound('User not found');
/// return Response.redirect('/login');
/// ```
///
/// Chain [withHeader] to add extra headers:
///
/// ```dart
/// return Response.json(data).withHeader('X-Request-Id', requestId);
/// ```
class Response {
  final int statusCode;
  final Object? _body;
  final Map<String, String> headers;

  const Response._({
    required this.statusCode,
    Object? body,
    Map<String, String> headers = const {},
  })  : _body = body,
        headers = headers;

  // ── 2xx ──────────────────────────────────────────────────────────────────

  /// 200 OK — serialises [data] as JSON.
  factory Response.json(
    dynamic data, {
    int status = 200,
    Map<String, String>? headers,
  }) =>
      Response._(
        statusCode: status,
        body: jsonEncode(data),
        headers: {'content-type': _jsonContentType, ...?headers},
      );

  /// 200 OK — plain-text body.
  factory Response.text(
    String text, {
    int status = 200,
    Map<String, String>? headers,
  }) =>
      Response._(
        statusCode: status,
        body: text,
        headers: {'content-type': _textContentType, ...?headers},
      );

  /// 200 OK — HTML body.
  factory Response.html(
    String html, {
    int status = 200,
    Map<String, String>? headers,
  }) =>
      Response._(
        statusCode: status,
        body: html,
        headers: {'content-type': _htmlContentType, ...?headers},
      );

  /// 201 Created — serialises [data] as JSON.
  factory Response.created(
    dynamic data, {
    Map<String, String>? headers,
  }) =>
      Response.json(data, status: 201, headers: headers);

  /// 204 No Content.
  factory Response.noContent() => const Response._(statusCode: 204);

  // ── 3xx ──────────────────────────────────────────────────────────────────

  /// 302 Found redirect (or [status] 301 for permanent redirect).
  factory Response.redirect(String location, {int status = 302}) =>
      Response._(
        statusCode: status,
        headers: {'location': location},
      );

  // ── 4xx ──────────────────────────────────────────────────────────────────

  /// 400 Bad Request.
  factory Response.badRequest([String message = 'Bad Request']) =>
      Response.json({'error': message}, status: 400);

  /// 401 Unauthorized.
  factory Response.unauthorized([String message = 'Unauthorized']) =>
      Response.json({'error': message}, status: 401);

  /// 403 Forbidden.
  factory Response.forbidden([String message = 'Forbidden']) =>
      Response.json({'error': message}, status: 403);

  /// 404 Not Found.
  factory Response.notFound([String message = 'Not Found']) =>
      Response.json({'error': message}, status: 404);

  /// 405 Method Not Allowed.
  factory Response.methodNotAllowed([String message = 'Method Not Allowed']) =>
      Response.json({'error': message}, status: 405);

  /// 409 Conflict.
  factory Response.conflict([String message = 'Conflict']) =>
      Response.json({'error': message}, status: 409);

  /// 422 Unprocessable Entity — validation errors.
  factory Response.unprocessable(dynamic errors) =>
      Response.json({'errors': errors}, status: 422);

  // ── 5xx ──────────────────────────────────────────────────────────────────

  /// 500 Internal Server Error.
  factory Response.serverError([String message = 'Internal Server Error']) =>
      Response.json({'error': message}, status: 500);

  // ── Builder ───────────────────────────────────────────────────────────────

  /// Returns a copy of this response with [key]/[value] added to the headers.
  Response withHeader(String key, String value) => Response._(
        statusCode: statusCode,
        body: _body,
        headers: {...headers, key.toLowerCase(): value},
      );

  /// Returns a copy of this response with [status] as the status code.
  Response withStatus(int status) => Response._(
        statusCode: status,
        body: _body,
        headers: headers,
      );

  // ── Shelf interop ─────────────────────────────────────────────────────────

  /// Converts to a [shelf.Response] for the underlying Shelf server.
  shelf.Response toShelf() =>
      shelf.Response(statusCode, body: _body?.toString(), headers: headers);

  @override
  String toString() => 'Response($statusCode)';
}
