import 'dart:io' show Platform;

import '../core/app.dart';
import '../http/request.dart';
import '../routing/route.dart';

// The helpers file holds the single shared application reference.
// [Application] sets [_sharedApp] in its constructor.
Application? _sharedApp;

void setSharedApp(Application app) => _sharedApp = app;

// ── Global helpers ────────────────────────────────────────────────────────

/// Returns the running [Application] instance.
///
/// Throws [StateError] if no application has been created yet.
Application app() {
  if (_sharedApp == null) {
    throw StateError(
      'No Application instance found. '
      'Call ShelfBase.createApp() or new Application() first.',
    );
  }
  return _sharedApp!;
}

/// Resolves [T] from the application IoC container.
///
/// Shorthand for `app().make<T>()`.
T make<T>() => app().make<T>();

/// Generates a URL for the named route [name] by substituting [params].
///
/// ```dart
/// route('users.show', {'id': '42'}); // → '/users/42'
/// ```
String route(String name, [Map<String, String> params = const {}]) {
  final r = app().router.findByName(name);
  if (r == null) throw ArgumentError('No route named "$name".');
  return r.url(params);
}

/// Reads an environment variable named [key].
///
/// Returns [fallback] if the variable is not set.
///
/// ```dart
/// final dbUrl = env('DATABASE_URL', fallback: 'postgres://localhost/dev');
/// ```
String env(String key, {String fallback = ''}) =>
    Platform.environment[key] ?? fallback;

/// Reads an environment variable and parses it as an integer.
///
/// Returns [fallback] if absent or not parseable.
int envInt(String key, {int fallback = 0}) =>
    int.tryParse(Platform.environment[key] ?? '') ?? fallback;

/// Returns the value of [Route] that was named [name], or `null`.
Route? namedRoute(String name) => app().router.findByName(name);

/// Resolves [T] from the IoC container on every request and dispatches to
/// the controller method returned by [selector].
///
/// This is the Laravel-inspired `[Controller::class, 'method']` equivalent
/// for ShelfBase. Register the controller type as a singleton in a
/// [ServiceProvider] so the container can resolve it.
///
/// ```dart
/// // routes/api.dart
/// r.get('/todos',       use<TodoController>((c) => c.index));
/// r.post('/todos',      use<TodoController>((c) => c.store));
/// r.get('/todos/<id>',  use<TodoController>((c) => c.show));
/// r.put('/todos/<id>',  use<TodoController>((c) => c.update));
/// r.delete('/todos/<id>', use<TodoController>((c) => c.destroy));
/// ```
RouteHandler use<T>(RouteHandler Function(T) selector) {
  return (Request req) => selector(make<T>())(req);
}
