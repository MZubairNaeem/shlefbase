import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';

/// Continuation function passed to [Middleware.handle].
///
/// Call `next(request)` to pass control to the next middleware or the
/// route handler.  You may modify [request] before forwarding it, or
/// intercept / replace the [Response] that comes back.
typedef Next = Future<Response> Function(Request request);

/// Interface for ShelfBase middleware.
///
/// ```dart
/// class AuthMiddleware implements Middleware {
///   @override
///   Future<Response> handle(Request request, Next next) async {
///     final token = request.bearerToken;
///     if (token == null) return Response.unauthorized();
///     return next(request);          // pass through
///   }
/// }
/// ```
abstract interface class Middleware {
  Future<Response> handle(Request request, Next next);
}
