# ShelfBase

> Laravel-inspired backend framework for Dart, built on [Shelf](https://pub.dev/packages/shelf).

ShelfBase brings Laravel's fluent routing, IoC container, middleware pipeline, service-provider lifecycle, and Artisan-style CLI to Dart server-side development — **no reflection, no mirrors, fully AOT-safe**.

---

## Features

| | |
|---|---|
| **Project scaffolding** | `dart run shelfbase init` creates the full skeleton in seconds |
| **Dev server** | `dart run shelfbase serve` auto-discovers your entry point |
| **Fluent router** | `get`, `post`, `put`, `patch`, `delete`, `resource`, nested `group` |
| **Laravel-style dispatch** | `use<Controller>((c) => c.method)` — controller actions from the IoC container |
| **IoC container** | `bind`, `singleton`, `instance`, `make` — zero reflection |
| **Service providers** | `register()` + `boot()` lifecycle, exactly like Laravel |
| **Middleware pipeline** | Global, per-group, and per-route middleware stacks |
| **Rich Request / Response** | `param`, `query`, `jsonMap`, `Response.json`, `Response.unprocessable`, … |
| **Resource controllers** | `router.resource('/users', ctrl)` registers all 6 CRUD routes |
| **Artisan-style CLI** | `make:resource`, `make:controller`, `make:service`, `make:middleware`, `make:provider` |
| **Shelf-native** | Produces a standard Shelf `Handler`; any Shelf middleware works |

---

## Getting started

### 1 — Add dependency

```yaml
# pubspec.yaml
dependencies:
  shelfbase:
    git:
      url: https://github.com/MZubairNaeem/shlefbase.git
      ref: main
```

### 2 — Install & scaffold

```bash
dart pub get
dart run shelfbase init
```

`init` creates the full project skeleton (safe to re-run — existing files are skipped):

```
bin/
  main.dart                    ← wired entry point
lib/
  routes/
    api.dart                   ← Laravel-style API routes
  controllers/
    home_controller.dart       ← sample ResourceController
  middleware/
    log_middleware.dart        ← request / response logger
    cors_middleware.dart       ← CORS headers + preflight
  providers/
    app_provider.dart          ← ServiceProvider stub
```

### 3 — Start the server

```bash
dart run shelfbase serve
# → http://localhost:8080
```

With options:

```bash
dart run shelfbase serve --port 3000
dart run shelfbase serve --host 0.0.0.0
dart run shelfbase serve --entry bin/api.dart   # explicit entry point
```

---

## Quick start (manual)

```dart
// bin/main.dart
import 'package:shelfbase/shelfbase.dart';

void main() async {
  final application = Application();

  application.register(AppProvider());

  application
    ..use(CorsMiddleware())
    ..use(LogMiddleware());

  application.router
      .get('/', (req) => Response.json({'message': 'Hello ShelfBase!'}));

  registerApiRoutes(application.router);

  await application.listen(port: envInt('PORT', fallback: 8080));
}
```

```dart
// lib/routes/api.dart
import 'package:shelfbase/shelfbase.dart';
import '../controllers/user_controller.dart';

void registerApiRoutes(Router r) {
  r.group(prefix: '/api', routes: (r) {
    // Laravel-style: use<Controller>((c) => c.method)
    r.get('/users',         use<UserController>((c) => c.index));
    r.post('/users',        use<UserController>((c) => c.store));
    r.get('/users/<id>',    use<UserController>((c) => c.show));
    r.put('/users/<id>',    use<UserController>((c) => c.update));
    r.patch('/users/<id>',  use<UserController>((c) => c.update));
    r.delete('/users/<id>', use<UserController>((c) => c.destroy));
  });
}
```

---

## Laravel-style routing

`use<T>(selector)` is the Dart equivalent of Laravel's `[Controller::class, 'method']`.  
It resolves `T` from the IoC container on every request and delegates to the selected method.

```dart
// Laravel (PHP)
Route::get('/users', [UserController::class, 'index']);

// ShelfBase (Dart)
r.get('/users', use<UserController>((c) => c.index));
```

**Requirements:**
- The controller must be registered as a singleton in a `ServiceProvider`.
- `use<T>()` is exported from `package:shelfbase/shelfbase.dart`.

```dart
// lib/providers/app_provider.dart
class AppProvider extends ServiceProvider {
  @override
  void register() {
    this.app.singleton<UserController>(
      (c) => UserController(c.make<UserService>()),
    );
  }
}
```

Resource shorthand (registers all 6 CRUD routes at once):

```dart
r.resource('/users', make<UserController>());
```

---

## Architecture

```
lib/
├── shelfbase.dart               ← single public import
└── src/
    ├── core/
    │   ├── app.dart             ← Application: container + router + middleware + server
    │   └── container.dart       ← IoC Container: bind / singleton / instance / make
    ├── http/
    │   ├── request.dart         ← Request: param / query / header / body / json
    │   └── response.dart        ← Response: json / text / html / created / notFound …
    ├── routing/
    │   ├── route.dart           ← Route value object
    │   ├── route_pattern.dart   ← RegExp URL matching + param extraction
    │   └── router.dart          ← Router + ResourceController
    ├── middleware/
    │   ├── middleware.dart      ← Middleware interface + Next typedef
    │   └── pipeline.dart        ← Pipeline.run(middleware, request, handler)
    └── support/
        ├── service_provider.dart ← ServiceProvider abstract (register + boot)
        └── helpers.dart          ← app() / make<T>() / use<T>() / route() / env()
```

---

## Developer guide

### Write a service

```dart
class UserService {
  final _users = <String, Map<String, dynamic>>{};

  List<Map<String, dynamic>> findAll() => _users.values.toList();
  Map<String, dynamic>? findOne(String id) => _users[id];

  Map<String, dynamic> create(String name, String email) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return _users[id] = {'id': id, 'name': name, 'email': email};
  }

  Map<String, dynamic>? update(String id, Map<String, dynamic> data) { ... }
  bool delete(String id) => _users.remove(id) != null;
}
```

### Write a controller

```dart
class UserController extends ResourceController {
  final UserService _service;
  UserController(this._service);

  @override
  Response index(Request req) {
    return Response.json({'data': _service.findAll()});
  }

  @override
  Response show(Request req) {
    final user = _service.findOne(req.param('id'));
    return user != null ? Response.json(user) : Response.notFound('Not found');
  }

  @override
  Future<Response> store(Request req) async {
    final body = await req.jsonMap();
    return Response.created(_service.create(body['name'], body['email']));
  }

  @override
  Future<Response> update(Request req) async {
    final body = await req.jsonMap();
    final user = _service.update(req.param('id'), body);
    return user != null ? Response.json(user) : Response.notFound('Not found');
  }

  @override
  Response destroy(Request req) {
    return _service.delete(req.param('id'))
        ? Response.noContent()
        : Response.notFound('Not found');
  }
}
```

`router.resource('/users', controller)` registers:

```
GET    /users         → controller.index
GET    /users/<id>    → controller.show
POST   /users         → controller.store
PUT    /users/<id>    → controller.update
PATCH  /users/<id>    → controller.update
DELETE /users/<id>    → controller.destroy
```

### Register with a provider

```dart
class AppProvider extends ServiceProvider {
  @override
  void register() {
    // bind<T>  → new instance on every make()
    // singleton<T> → created once, shared forever
    this.app.singleton<UserService>((_) => UserService());
    this.app.singleton<UserController>(
      (c) => UserController(c.make<UserService>()),
    );
  }

  @override
  Future<void> boot() async {
    // All providers are registered — safe to call app.make<T>() here.
    // Good for async setup: DB connections, migrations, cache warm-up.
  }
}
```

---

## IoC container

```dart
// Transient — new instance on every make()
app.bind<MyService>((_) => MyService());

// Singleton — created once, reused forever
app.singleton<MyService>((_) => MyService());

// Pre-built instance
app.instance<Config>(Config.fromEnv());

// Resolve
final svc = app.make<MyService>();

// Global helper (anywhere in the app)
final svc = make<MyService>();

// Override in tests
app.rebind<MyService>((_) => FakeMyService());

if (app.bound<MyService>()) { ... }
```

---

## Routing

### Verb methods

```dart
app.router.get('/path', handler);
app.router.post('/path', handler);
app.router.put('/path', handler);
app.router.patch('/path', handler);
app.router.delete('/path', handler);
app.router.any('/path', handler);     // any HTTP method
```

### Route parameters

```dart
app.router.get('/users/<id>', (req) {
  return Response.json({'id': req.param('id')});
});
```

### Named routes and URL generation

```dart
app.router.get('/users/<id>', handler).name('users.show');

final url = route('users.show', {'id': '42'}); // → /users/42
```

### Route groups

```dart
app.router.group(
  prefix: '/api/v1',
  middleware: [AuthMiddleware()],
  routes: (r) {
    r.resource('/users', make<UserController>());

    r.group(prefix: '/admin', middleware: [AdminMiddleware()], routes: (r) {
      r.get('/stats', (req) => Response.json({'stats': 'data'}));
    });
  },
);
```

---

## Middleware

```dart
class AuthMiddleware implements Middleware {
  @override
  Future<Response> handle(Request request, Next next) async {
    final token = request.bearerToken;
    if (token == null) return Response.unauthorized();
    return next(request);
  }
}

// Global — every request
app.use(LogMiddleware());

// Per group
app.router.group(middleware: [AuthMiddleware()], routes: (r) { ... });
```

---

## Request API

```dart
request.param('id')              // route parameter  /<id>
request.query('page')            // query string  ?page=2
request.queryAll                 // Map<String, String>

request.header('content-type')
request.authorization            // Authorization header
request.bearerToken              // Bearer <token> extracted

await request.body()             // raw String (cached)
await request.json()             // dynamic
await request.jsonMap()          // Map<String, dynamic>
await request.input('name')      // single JSON key
await request.form()             // URL-encoded form fields

request.method                   // 'GET', 'POST', …
request.path                     // '/users/42'
request.uri                      // full Uri
request.isJson                   // content-type check
request.ip                       // best-effort client IP
```

---

## Response helpers

```dart
Response.json({'users': users})          // 200 application/json
Response.json(data, status: 202)         // custom status
Response.text('hello')                   // 200 text/plain
Response.html('<h1>hi</h1>')             // 200 text/html
Response.created({'id': newId})          // 201
Response.noContent()                     // 204
Response.redirect('/login')              // 302
Response.redirect('/new', status: 301)   // 301 permanent

Response.badRequest('name required')     // 400
Response.unauthorized()                  // 401
Response.forbidden()                     // 403
Response.notFound('User not found')      // 404
Response.methodNotAllowed()              // 405
Response.conflict()                      // 409
Response.unprocessable({'field': ['required']})  // 422
Response.serverError()                   // 500

// Chain
Response.json(data).withHeader('X-Request-Id', id)
Response.json(data).withStatus(202)
```

---

## Helper functions

```dart
import 'package:shelfbase/shelfbase.dart';

app()                             // the Application singleton
make<T>()                         // resolve T from the container
use<T>((c) => c.method)           // controller-action dispatch helper
route('users.show', {'id': '42'}) // URL for a named route
env('DATABASE_URL')               // read environment variable
env('PORT', fallback: '8080')     // with string fallback
envInt('PORT', fallback: 8080)    // parsed as int
```

---

## CLI reference

### `dart run shelfbase init`

Scaffold a new project structure. Run once after `dart pub get`.

```bash
dart run shelfbase init            # create skeleton
dart run shelfbase init --dry-run  # preview without writing
dart run shelfbase init --force    # overwrite existing files
```

### `dart run shelfbase serve`

Start the application server. Auto-discovers the entry point.

```bash
dart run shelfbase serve                        # auto-discover bin/main.dart
dart run shelfbase serve --port 3000            # override PORT env var
dart run shelfbase serve --host 0.0.0.0         # override HOST env var
dart run shelfbase serve --entry bin/api.dart   # explicit entry
```

Entry-point discovery order:
1. `--entry` flag
2. `bin/main.dart`
3. `bin/<pubspec-name>.dart`
4. First `*.dart` file in `bin/`

### `dart run shelfbase make:*`

Generate boilerplate files from templates.

| Command | Creates |
|---|---|
| `make:resource <Name>` | service + controller + module + **`lib/routes/api.dart`** |
| `make:controller <Name>` | `<name>.controller.dart` with CRUD stubs |
| `make:service <Name>` | `<name>.service.dart` with CRUD stubs |
| `make:middleware <Name>` | `<name>.middleware.dart` |
| `make:provider <Name>` | `<name>.provider.dart` |
| `make:module <Name>` | `<name>.module.dart` registration function |

`make:resource` also creates or updates `lib/routes/api.dart`:
- **First resource** → file created with full scaffold and wired routes.
- **Subsequent resources** → hint block printed so you can paste the new routes in without clobbering your custom edits.

```bash
dart run shelfbase make:resource User
dart run shelfbase make:resource Order --path api/v1
dart run shelfbase make:middleware Auth
dart run shelfbase make:resource Payment --dry-run
dart run shelfbase make:resource User --force
```

**Flags available on all `make:*` commands:**

| Flag | Short | Description |
|---|---|---|
| `--dry-run` | `-d` | Preview output without writing |
| `--force` | `-f` | Overwrite existing files |
| `--flat` | | Write to `lib/` without a subdirectory |
| `--path <dir>` | `-p` | Write into `lib/<dir>/` |
| `--no-service` | | (controller only) Skip service import |

---

## How ShelfBase compares

| | Raw Shelf | ShelfBase |
|---|---|---|
| Routing | Manual `shelf_router` setup | Fluent `router.get/post/resource/group` |
| DI | None | IoC container — `bind / singleton / make` |
| Middleware | Shelf pipeline | Composable, stackable middleware classes |
| Organisation | Ad-hoc | Service providers + resource controllers |
| Bootstrapping | `shelf_io.serve(handler, …)` | `Application().listen()` |
| Scaffolding | None | `init` + `make:resource` |
| Dev server | `dart run bin/main.dart` | `dart run shelfbase serve` |

### Laravel concept mapping

| Laravel | ShelfBase |
|---|---|
| `php artisan make:resource User` | `dart run shelfbase make:resource User` |
| `php artisan serve` | `dart run shelfbase serve` |
| `Route::get('/path', fn)` | `router.get('/path', handler)` |
| `Route::get('/users', [UserController::class, 'index'])` | `r.get('/users', use<UserController>((c) => c.index))` |
| `Route::apiResource('users', UserController::class)` | `router.resource('/users', make<UserController>())` |
| `Route::group(['prefix' => '/api', 'middleware' => [Auth::class]], fn)` | `router.group(prefix: '/api', middleware: [AuthMiddleware()], routes: …)` |
| `ServiceProvider::register()` / `boot()` | `ServiceProvider.register()` / `boot()` |
| `app()->singleton(T::class, fn)` | `app.singleton<T>((_) => …)` |
| `app()->make(T::class)` | `app.make<T>()` or `make<T>()` |
| `$request->route('id')` | `request.param('id')` |
| `$request->query('page')` | `request.query('page')` |
| `response()->json(data)` | `Response.json(data)` |

---

## Roadmap

### Phase 1 — MVP ✅

- `Application` — IoC container + router + middleware + HTTP server
- `Container` — `bind / singleton / instance / make / rebind`
- `ServiceProvider` — `register()` + `boot()` two-phase lifecycle
- `Router` — verb methods, `resource`, nested `group`, named routes, URL generation
- Custom regex URL matching — no `shelf_router` dependency
- `Middleware` interface + composable `Pipeline`
- `Request` — params, query, headers, body, cached JSON parsing
- `Response` — full set of factory helpers (200 → 500)
- `ResourceController` abstract class
- **CLI**
  - `init` — scaffold full project skeleton (bin + routes + controllers + middleware + providers)
  - `serve` — auto-discover entry point, inherit stdio, `--port` / `--host` env override
  - `make:controller | make:service | make:middleware | make:provider | make:module | make:resource`
  - `make:resource` auto-creates / updates `lib/routes/api.dart`
  - `use<T>(selector)` helper — Laravel-style controller-action dispatch from IoC container
  - `--flat`, `--dry-run`, `--force`, `--path` flags; suffix stripping; SKIP guard

### Phase 2 — Code generation

- `shelfbase_generator` package using `build_runner` + `source_gen`
- Annotations at build time → auto-generates `singleton` / `bind` registration code
- Eliminates manual provider wiring

### Phase 3 — Guards, interceptors, pipes

- `Guard` — pre-handler authorisation checks
- `Interceptor` — pre/post handler transform
- `ExceptionFilter` — structured error response handling
- `Pipe` — request body validation and transformation

### Phase 4 — Production readiness

- Request-scoped providers
- Graceful shutdown hooks
- `pub.dev` publication (`shelfbase` + `shelfbase_generator`)
- Full API documentation site

---

## Running tests

```bash
dart test
```

---

## Design philosophy

> "Simple by default, extensible when you need it."

- **No reflection** — works with AOT (Dart Native). No `dart:mirrors`, no runtime scanning.
- **Explicit over magic** — wiring is deliberate; you see exactly what the framework does.
- **Laravel concepts, Dart idioms** — the *architecture* from Laravel, not the *syntax*.
- **Shelf-native** — ShelfBase is a thin orchestration layer over Shelf. Any Shelf middleware works.
