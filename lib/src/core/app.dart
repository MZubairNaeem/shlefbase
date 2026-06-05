import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../http/request.dart';
import '../http/response.dart';
import '../middleware/middleware.dart';
import '../middleware/pipeline.dart';
import '../routing/router.dart';
import '../support/helpers.dart' as helpers;
import '../support/service_provider.dart';
import 'container.dart';

/// The Laravel-style application — the single object that owns the container,
/// the router, global middleware, and the HTTP server.
///
/// Create one instance per process, then configure and boot it:
///
/// ```dart
/// void main() async {
///   final app = Application();
///
///   app.register(DatabaseServiceProvider());
///   app.use(CorsMiddleware());
///
///   app.router.get('/', (req) => Response.json({'status': 'ok'}));
///   app.router.resource('/users', UserController());
///
///   await app.listen(port: 3000);
/// }
/// ```
class Application {
  final Container _container;

  /// The application router. Register routes here before calling [listen].
  final Router router;

  final List<Middleware> _globalMiddleware = [];
  final List<ServiceProvider> _providers = [];

  HttpServer? _server;

  Application()
      : _container = Container(),
        router = Router() {
    helpers.setSharedApp(this);
  }

  // ── Container ─────────────────────────────────────────────────────────────

  /// Bind a transient service — new instance on every [make].
  void bind<T>(T Function(Container c) factory) =>
      _container.bind<T>(factory);

  /// Bind a singleton service — created once and reused.
  void singleton<T>(T Function(Container c) factory) =>
      _container.singleton<T>(factory);

  /// Register a pre-built [value] as a singleton.
  void instance<T>(T value) => _container.instance<T>(value);

  /// Resolve [T] from the container.
  T make<T>() => _container.make<T>();

  /// Whether a binding exists for [T].
  bool bound<T>() => _container.bound<T>();

  // ── Middleware ────────────────────────────────────────────────────────────

  /// Adds [middleware] to the global stack (applied to every request).
  ///
  /// ```dart
  /// app.use(CorsMiddleware());
  /// app.use(LogMiddleware());
  /// ```
  Application use(Middleware middleware) {
    _globalMiddleware.add(middleware);
    return this;
  }

  // ── Service providers ─────────────────────────────────────────────────────

  /// Registers a [ServiceProvider] and immediately calls its [ServiceProvider.register].
  ///
  /// [ServiceProvider.boot] is called later, after all providers are registered,
  /// just before the server starts.
  Application register(ServiceProvider provider) {
    provider.app = this;
    _providers.add(provider);
    provider.register();
    return this;
  }

  // ── Startup ───────────────────────────────────────────────────────────────

  /// Starts the HTTP server on [host]:[port].
  ///
  /// Boots all service providers, then begins accepting requests.
  Future<void> listen({
    int port = 3000,
    String host = 'localhost',
    bool shared = false,
  }) async {
    await _bootProviders();

    final shelfHandler = _buildShelfHandler();
    _server = await shelf_io.serve(shelfHandler, host, port, shared: shared);

    _printBanner(host, port);
  }

  /// The underlying [HttpServer]. `null` before [listen].
  HttpServer? get server => _server;

  /// Gracefully shuts down the HTTP server.
  Future<void> close({bool force = false}) async {
    await _server?.close(force: force);
  }

  // ── private ───────────────────────────────────────────────────────────────

  Future<void> _bootProviders() async {
    for (final p in _providers) {
      await p.boot();
    }
  }

  shelf.Handler _buildShelfHandler() {
    return (shelf.Request shelfReq) async {
      try {
        return await _dispatch(shelfReq);
      } catch (e, stack) {
        _log('ERROR ${shelfReq.method} ${shelfReq.url.path}\n$e\n$stack');
        return Response.serverError().toShelf();
      }
    };
  }

  Future<shelf.Response> _dispatch(shelf.Request shelfReq) async {
    final method = shelfReq.method.toUpperCase();
    final path = shelfReq.requestedUri.path;

    // Find first matching route.
    for (final route in router.routes) {
      final params = route.tryMatch(method, path);
      if (params == null) continue;

      final request = Request(shelfReq, params: params);

      // Global middleware → route-specific middleware → handler.
      final allMiddleware = [..._globalMiddleware, ...route.middleware];
      final response = await Pipeline.run(allMiddleware, request, route.handler);

      return response.toShelf();
    }

    // 404 — no route matched.
    return Response.notFound(
      'Cannot $method $path',
    ).toShelf();
  }

  void _printBanner(String host, int port) {
    final count = router.routes.length;
    _log('');
    _log('┌──────────────────────────────────────────┐');
    _log('│            ShelfBase  v0.1.0             │');
    _log('└──────────────────────────────────────────┘');
    _log('');
    _log('Registered routes ($count):');
    _log(router.describe());
    _log('');
    _log('Server listening → http://$host:$port');
    _log('');
  }

  static void _log(String msg) => print('[ShelfBase] $msg');
}
