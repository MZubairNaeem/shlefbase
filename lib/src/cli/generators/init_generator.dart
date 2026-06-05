import 'dart:io';

import 'generator_base.dart';

/// Scaffolds a fresh ShelfBase project in the current working directory.
///
/// Run once after adding shelfbase to pubspec.yaml and running dart pub get:
/// ```
/// dart run shelfbase init
/// ```
///
/// Generated structure:
/// ```
/// bin/
///   main.dart                    ← app entry point
/// lib/
///   routes/
///     api.dart                   ← Laravel-style API routes
///   controllers/
///     home_controller.dart       ← sample ResourceController
///   middleware/
///     log_middleware.dart        ← request / response logger
///     cors_middleware.dart       ← CORS headers + preflight
///   providers/
///     app_provider.dart          ← ServiceProvider stub
/// ```
abstract final class InitGenerator {
  static Future<void> generate({
    bool dryRun = false,
    bool force = false,
  }) async {
    final projectName = _readProjectName();

    GeneratorBase.printHeading(
      'Initialising ShelfBase project: $projectName',
    );

    await GeneratorBase.writeFile(
      'bin/main.dart',
      _mainTemplate(projectName),
      dryRun: dryRun,
      force: force,
    );
    await GeneratorBase.writeFile(
      'lib/routes/api.dart',
      _routesTemplate(),
      dryRun: dryRun,
      force: force,
    );
    await GeneratorBase.writeFile(
      'lib/controllers/home_controller.dart',
      _homeControllerTemplate(),
      dryRun: dryRun,
      force: force,
    );
    await GeneratorBase.writeFile(
      'lib/middleware/log_middleware.dart',
      _logMiddlewareTemplate(),
      dryRun: dryRun,
      force: force,
    );
    await GeneratorBase.writeFile(
      'lib/middleware/cors_middleware.dart',
      _corsMiddlewareTemplate(),
      dryRun: dryRun,
      force: force,
    );
    await GeneratorBase.writeFile(
      'lib/providers/app_provider.dart',
      _appProviderTemplate(),
      dryRun: dryRun,
      force: force,
    );

    GeneratorBase.printDone();
    if (!dryRun) _printNextSteps();
  }

  // ── pubspec helper ────────────────────────────────────────────────────────

  static String _readProjectName() {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) return 'app';
    final content = pubspec.readAsStringSync();
    final match = RegExp(r'^name:\s+(\S+)', multiLine: true).firstMatch(content);
    return match?.group(1) ?? 'app';
  }

  // ── templates ─────────────────────────────────────────────────────────────

  static String _mainTemplate(String pkg) => '''
import 'package:shelfbase/shelfbase.dart';

import 'package:$pkg/middleware/cors_middleware.dart';
import 'package:$pkg/middleware/log_middleware.dart';
import 'package:$pkg/providers/app_provider.dart';
import 'package:$pkg/routes/api.dart';

void main() async {
  final application = Application();

  // ── Service providers ────────────────────────────────────────────────────
  // Register your ServiceProviders here. Each provider's register() is called
  // immediately; boot() is called just before the server starts.
  application.register(AppProvider());

  // ── Global middleware ────────────────────────────────────────────────────
  // Applied to every request in the order they are added.
  application
    ..use(CorsMiddleware())   // CORS headers on every response
    ..use(LogMiddleware());   // log method + path + status + duration

  // ── Routes ───────────────────────────────────────────────────────────────
  application.router
      .get('/', (req) => Response.json({'message': 'Welcome to ShelfBase!'}))
      .name('home');

  // API routes are declared in lib/routes/api.dart.
  registerApiRoutes(application.router);

  // ── Start ────────────────────────────────────────────────────────────────
  final port = envInt('PORT', fallback: 8080);
  await application.listen(port: port);
}
''';

  static String _routesTemplate() => '''
import 'package:shelfbase/shelfbase.dart';

// Import your controllers here and add routes using use<Controller>():
// import '../controllers/user_controller.dart';

/// Registers all API routes.
///
/// Laravel-style dispatch — use<ControllerType>((c) => c.method) resolves
/// the controller from the IoC container and delegates to the method.
/// Controllers must be registered as singletons in a [ServiceProvider].
///
/// ```dart
/// r.get('/users',       use<UserController>((c) => c.index));
/// r.post('/users',      use<UserController>((c) => c.store));
/// r.get('/users/<id>',  use<UserController>((c) => c.show));
/// r.put('/users/<id>',  use<UserController>((c) => c.update));
/// r.delete('/users/<id>', use<UserController>((c) => c.destroy));
/// ```
void registerApiRoutes(Router r) {
  r.group(
    prefix: '/api',
    routes: (r) {
      // Health check — always available.
      r.get('/health', (req) => Response.json({'status': 'ok'}))
          .name('api.health');

      // ── Add your resource routes below ──────────────────────────────────
      // Generate a resource: dart run shelfbase make:resource <Name>
      // Then add routes using use<ControllerType>((c) => c.method):
      //
      // r.get('/users',         use<UserController>((c) => c.index));
      // r.post('/users',        use<UserController>((c) => c.store));
      // r.get('/users/<id>',    use<UserController>((c) => c.show));
      // r.put('/users/<id>',    use<UserController>((c) => c.update));
      // r.patch('/users/<id>',  use<UserController>((c) => c.update));
      // r.delete('/users/<id>', use<UserController>((c) => c.destroy));
    },
  );
}
''';

  static String _homeControllerTemplate() => '''
import 'package:shelfbase/shelfbase.dart';

/// Sample controller — delete or adapt for your own use.
///
/// Register it in a [ServiceProvider] to use it with Laravel-style routing:
///   app.singleton<HomeController>((_) => HomeController());
///
/// Then in lib/routes/api.dart:
///   r.get('/home', use<HomeController>((c) => c.index));
class HomeController extends ResourceController {
  @override
  Response index(Request req) {
    return Response.json({'message': 'Hello from HomeController!'});
  }

  @override
  Response show(Request req) {
    final id = req.param('id');
    return Response.json({'id': id});
  }

  @override
  Future<Response> store(Request req) async {
    final body = await req.jsonMap();
    return Response.created(body);
  }

  @override
  Future<Response> update(Request req) async {
    final body = await req.jsonMap();
    return Response.json(body);
  }

  @override
  Response destroy(Request req) {
    return Response.noContent();
  }
}
''';

  static String _logMiddlewareTemplate() => '''
import 'package:shelfbase/shelfbase.dart';

/// Logs each request method, path, status code, and duration to stdout.
class LogMiddleware implements Middleware {
  @override
  Future<Response> handle(Request request, Next next) async {
    final watch = Stopwatch()..start();
    final response = await next(request);
    watch.stop();
    print(
      '[LOG] \${request.method.padRight(7)} '
      '\${request.path.padRight(35)} '
      '\${response.statusCode}  '
      '\${watch.elapsedMilliseconds}ms',
    );
    return response;
  }
}
''';

  static String _corsMiddlewareTemplate() => '''
import 'package:shelfbase/shelfbase.dart';

/// Adds CORS headers to every response and handles OPTIONS preflight requests.
class CorsMiddleware implements Middleware {
  final String allowOrigin;
  final String allowMethods;
  final String allowHeaders;

  const CorsMiddleware({
    this.allowOrigin = '*',
    this.allowMethods = 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    this.allowHeaders = 'Content-Type, Authorization',
  });

  @override
  Future<Response> handle(Request request, Next next) async {
    if (request.method == 'OPTIONS') {
      return Response.noContent()
          .withHeader('Access-Control-Allow-Origin', allowOrigin)
          .withHeader('Access-Control-Allow-Methods', allowMethods)
          .withHeader('Access-Control-Allow-Headers', allowHeaders);
    }

    final response = await next(request);
    return response
        .withHeader('Access-Control-Allow-Origin', allowOrigin)
        .withHeader('Access-Control-Allow-Methods', allowMethods)
        .withHeader('Access-Control-Allow-Headers', allowHeaders);
  }
}
''';

  static String _appProviderTemplate() => '''
import 'package:shelfbase/shelfbase.dart';

/// Application service provider — bind your services here.
///
/// Two-phase lifecycle:
///   register() — bind services. Do NOT call app.make<T>() yet.
///   boot()     — safe to call app.make<T>(); runs after all providers register.
class AppProvider extends ServiceProvider {
  @override
  void register() {
    // Transient — new instance on every make<T>():
    //   app.bind<MyService>((_) => MyService());
    //
    // Singleton — created once, reused forever:
    //   app.singleton<MyService>((_) => MyService());
  }

  @override
  Future<void> boot() async {
    // Async setup: database connections, cache warm-up, migrations…
  }
}
''';

  // ── next-steps banner ─────────────────────────────────────────────────────

  static void _printNextSteps() {
    stdout.writeln('''
\x1B[32m✓\x1B[0m  Project initialised! Next steps:

  \x1B[36m1.\x1B[0m  Start the server:
         dart run shelfbase serve

  \x1B[36m2.\x1B[0m  Generate a resource (service + controller + routes):
         dart run shelfbase make:resource <Name>

  \x1B[36m3.\x1B[0m  Register the controller in lib/providers/app_provider.dart,
      then wire its routes in lib/routes/api.dart.

  \x1B[36m4.\x1B[0m  For custom port:
         dart run shelfbase serve --port 3000
''');
  }
}
