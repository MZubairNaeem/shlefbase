import 'dart:io' show Platform;

import '../core/app.dart';
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
