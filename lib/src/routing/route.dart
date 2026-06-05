import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../middleware/middleware.dart';
import 'route_pattern.dart';

/// Type of a route handler function.
typedef RouteHandler = FutureOr<Response> Function(Request request);

/// A single registered route: verb + pattern + handler + optional middleware.
///
/// Routes are created by [Router] methods ([Router.get], [Router.post], …)
/// and are not normally instantiated directly.
///
/// Chain [name] to register the route for URL generation:
/// ```dart
/// router.get('/users/<id>', UserController.show).name('users.show');
/// ```
class Route {
  final String method;
  final String path;
  final RouteHandler handler;
  final List<Middleware> middleware;

  /// The compiled pattern for URL matching and param extraction.
  late final RoutePattern _pattern = RoutePattern(path);

  /// Back-reference to the router's named-route registry so [name] can
  /// register the route lazily.
  final Map<String, Route> _namedRoutes;

  String? _name;

  Route({
    required this.method,
    required this.path,
    required this.handler,
    required Map<String, Route> namedRoutes,
    List<Middleware> middleware = const [],
  })  : middleware = List.unmodifiable(middleware),
        _namedRoutes = namedRoutes;

  // ── fluent API ────────────────────────────────────────────────────────────

  /// Assigns a name to this route and registers it for URL generation.
  ///
  /// ```dart
  /// router.get('/users/<id>', handler).name('users.show');
  /// // later:
  /// route('users.show', {'id': '42'}); // → '/users/42'
  /// ```
  Route name(String n) {
    _namedRoutes[n] = this;
    _name = n;
    return this;
  }

  // ── matching ──────────────────────────────────────────────────────────────

  /// Returns extracted params if this route matches [method] and [path].
  Map<String, String>? tryMatch(String method, String path) {
    if (this.method != 'ANY' && this.method != method) return null;
    return _pattern.match(path);
  }

  // ── accessors ─────────────────────────────────────────────────────────────

  String? get routeName => _name;

  /// Generates the URL for this route by substituting [params].
  String url([Map<String, String> params = const {}]) =>
      _pattern.url(params);

  @override
  String toString() => '${method.padRight(7)} $path${_name != null ? '  (${'name'}=$_name)' : ''}';
}
