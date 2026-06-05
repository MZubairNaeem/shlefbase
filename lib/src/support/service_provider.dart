import '../core/app.dart';

/// Base class for all ShelfBase service providers.
///
/// Service providers are the central place to configure the application.
/// They have two lifecycle hooks:
///
///   [register] — bind services into the container.  Called before [boot].
///   [boot]     — run code that depends on other providers being registered.
///
/// ```dart
/// class DatabaseServiceProvider extends ServiceProvider {
///   @override
///   void register() {
///     app.singleton<Database>((c) => Database(
///       url: env('DATABASE_URL', fallback: 'postgres://localhost/mydb'),
///     ));
///   }
///
///   @override
///   Future<void> boot() async {
///     await app.make<Database>().connect();
///   }
/// }
/// ```
abstract class ServiceProvider {
  late Application app;

  /// Bind services into the IoC container.
  ///
  /// Do **not** call [app.make] here — other providers may not have run yet.
  void register() {}

  /// Run code that requires other providers to already be registered.
  Future<void> boot() async {}
}
