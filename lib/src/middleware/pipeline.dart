import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import 'middleware.dart';

/// Runs a [Request] through a stack of [Middleware] layers, then calls
/// the final [handler].
///
/// Middleware is invoked in registration order (outermost first).
/// Each layer receives a [Next] that advances to the next layer.
///
/// ```
/// [LogMiddleware] → [AuthMiddleware] → routeHandler
/// ```
abstract final class Pipeline {
  const Pipeline._();

  /// Passes [request] through [middleware] and finally calls [handler].
  static Future<Response> run(
    List<Middleware> middleware,
    Request request,
    FutureOr<Response> Function(Request) handler,
  ) {
    return _dispatch(middleware, 0, request, handler);
  }

  static Future<Response> _dispatch(
    List<Middleware> stack,
    int index,
    Request request,
    FutureOr<Response> Function(Request) handler,
  ) {
    if (index >= stack.length) return Future.value(handler(request));
    return stack[index].handle(
      request,
      (req) => _dispatch(stack, index + 1, req, handler),
    );
  }
}
