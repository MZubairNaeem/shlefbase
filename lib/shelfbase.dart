/// ShelfBase — Laravel-inspired backend framework for Dart, built on Shelf.
///
/// Import this single file in your application:
/// ```dart
/// import 'package:shelfbase/shelfbase.dart';
/// ```
library shelfbase;

// ── Core ───────────────────────────────────────────────────────────────────
export 'src/core/app.dart' show Application;
export 'src/core/container.dart' show Container;

// ── Routing ────────────────────────────────────────────────────────────────
export 'src/routing/route.dart' show Route, RouteHandler;
export 'src/routing/route_pattern.dart' show RoutePattern;
export 'src/routing/router.dart' show Router, ResourceController;

// ── HTTP ───────────────────────────────────────────────────────────────────
export 'src/http/request.dart' show Request;
export 'src/http/response.dart' show Response;

// ── Middleware ─────────────────────────────────────────────────────────────
export 'src/middleware/middleware.dart' show Middleware, Next;
export 'src/middleware/pipeline.dart' show Pipeline;

// ── Support ────────────────────────────────────────────────────────────────
export 'src/support/service_provider.dart' show ServiceProvider;
export 'src/support/helpers.dart' show app, make, route, env, envInt, use;
