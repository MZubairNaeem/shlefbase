import 'dart:async';

import '../http/request.dart';
import '../http/response.dart';
import '../middleware/middleware.dart';
import 'route.dart';

/// Abstract base class for resource controllers.
///
/// Pass an instance to [Router.resource] to register all five
/// conventional CRUD routes at once.
///
/// ```dart
/// router.resource('/users', UserController());
///
/// class UserController extends ResourceController {
///   @override
///   Response index(Request req) => Response.json(service.findAll());
///   // ...
/// }
/// ```
abstract class ResourceController {
  FutureOr<Response> index(Request request);
  FutureOr<Response> show(Request request);
  FutureOr<Response> store(Request request);
  FutureOr<Response> update(Request request);
  FutureOr<Response> destroy(Request request);
}

/// Shared collection of registered routes and named-route index.
///
/// All [Router] instances produced by [Router.group] share the same
/// [_RouteCollection] so routes end up in one flat list on the root.
class _RouteCollection {
  final List<Route> routes = [];
  final Map<String, Route> namedRoutes = {};
}

/// Laravel-inspired fluent router.
///
/// Register routes with HTTP-verb methods and organise them into groups:
///
/// ```dart
/// app.router
///   .get('/', (req) => Response.json({'status': 'ok'}))
///   .name('home');
///
/// app.router.group(prefix: '/api/v1', middleware: [AuthMiddleware()], (r) {
///   r.resource('/users', UserController());
///
///   r.group(prefix: '/admin', middleware: [AdminMiddleware()], (r) {
///     r.get('/stats', StatsController.show);
///   });
/// });
/// ```
class Router {
  final _RouteCollection _col;
  final String _prefix;
  final List<Middleware> _middleware;

  /// Creates the root router.
  Router()
      : _col = _RouteCollection(),
        _prefix = '',
        _middleware = [];

  /// Creates a child router that shares the parent's [_RouteCollection].
  Router._child(this._col, this._prefix, this._middleware);

  // ── Verb methods ──────────────────────────────────────────────────────────

  /// Registers a GET route.
  Route get(String path, RouteHandler handler) =>
      _add('GET', path, handler);

  /// Registers a POST route.
  Route post(String path, RouteHandler handler) =>
      _add('POST', path, handler);

  /// Registers a PUT route.
  Route put(String path, RouteHandler handler) =>
      _add('PUT', path, handler);

  /// Registers a PATCH route.
  Route patch(String path, RouteHandler handler) =>
      _add('PATCH', path, handler);

  /// Registers a DELETE route.
  Route delete(String path, RouteHandler handler) =>
      _add('DELETE', path, handler);

  /// Registers a route that matches **any** HTTP method.
  Route any(String path, RouteHandler handler) =>
      _add('ANY', path, handler);

  // ── Resource routing ──────────────────────────────────────────────────────

  /// Registers five conventional CRUD routes for [controller]:
  ///
  /// ```
  /// GET    /path         → controller.index
  /// GET    /path/<id>    → controller.show
  /// POST   /path         → controller.store
  /// PUT    /path/<id>    → controller.update
  /// PATCH  /path/<id>    → controller.update
  /// DELETE /path/<id>    → controller.destroy
  /// ```
  void resource(String path, ResourceController controller) {
    _add('GET', path, controller.index);
    _add('GET', '$path/<id>', controller.show);
    _add('POST', path, controller.store);
    _add('PUT', '$path/<id>', controller.update);
    _add('PATCH', '$path/<id>', controller.update);
    _add('DELETE', '$path/<id>', controller.destroy);
  }

  // ── Route groups ──────────────────────────────────────────────────────────

  /// Creates a scoped group of routes that share a [prefix] and/or
  /// [middleware].
  ///
  /// Groups can be nested — prefixes and middleware accumulate:
  ///
  /// ```dart
  /// router.group(prefix: '/api', middleware: [AuthMiddleware()], (r) {
  ///   r.group(prefix: '/v1', (r) {
  ///     r.get('/users', UserController.index); // → GET /api/v1/users
  ///   });
  /// });
  /// ```
  void group({
    String prefix = '',
    List<Middleware> middleware = const [],
    required void Function(Router router) routes,
  }) {
    final child = Router._child(
      _col,
      _prefix + prefix,
      [..._middleware, ...middleware],
    );
    routes(child);
  }

  /// Shorthand for grouping under a common URL prefix without middleware.
  ///
  /// ```dart
  /// router.prefix('/api/v1').group((r) {
  ///   r.get('/users', UserController.index);
  /// });
  /// ```
  _PrefixBuilder prefix(String prefix) => _PrefixBuilder(this, prefix);

  // ── Inspection ────────────────────────────────────────────────────────────

  /// All registered routes in registration order.
  List<Route> get routes => List.unmodifiable(_col.routes);

  /// Named-route index (populated by [Route.name]).
  Map<String, Route> get namedRoutes => Map.unmodifiable(_col.namedRoutes);

  /// Returns a named route by [name], or `null`.
  Route? findByName(String name) => _col.namedRoutes[name];

  /// Formatted listing of all routes (useful at startup).
  String describe() {
    if (_col.routes.isEmpty) return '  (no routes registered)';
    return _col.routes.map((r) => '  $r').join('\n');
  }

  // ── private ───────────────────────────────────────────────────────────────

  Route _add(String method, String path, RouteHandler handler) {
    final route = Route(
      method: method,
      path: _prefix + path,
      handler: handler,
      middleware: List.of(_middleware),
      namedRoutes: _col.namedRoutes,
    );
    _col.routes.add(route);
    return route;
  }
}

/// Fluent builder returned by [Router.prefix].
class _PrefixBuilder {
  final Router _router;
  final String _prefix;
  final List<Middleware> _middleware = [];

  _PrefixBuilder(this._router, this._prefix);

  _PrefixBuilder middleware(List<Middleware> m) {
    _middleware.addAll(m);
    return this;
  }

  void group(void Function(Router router) routes) {
    _router.group(prefix: _prefix, middleware: _middleware, routes: routes);
  }
}
