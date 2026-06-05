# ShelfBase

> Laravel-inspired backend framework for Dart, built on top of [Shelf](https://pub.dev/packages/shelf).

ShelfBase brings Laravel's fluent routing, IoC container, middleware pipeline, and service-provider lifecycle to Dart server-side development — without reflection, without mirrors, fully AOT-safe.

- **Fluent router** — `get`, `post`, `put`, `patch`, `delete`, `any`, `resource`, nested `group`
- **IoC container** — `bind`, `singleton`, `instance`, `make` — no reflection
- **Service providers** — `register()` + `boot()` lifecycle, exactly like Laravel
- **Middleware pipeline** — global, per-group, and per-route middleware stacks
- **Rich Request/Response** — `request.param`, `request.query`, `request.jsonMap`, `Response.json`, etc.
- **Resource controllers** — `router.resource('/users', UserController())` registers all 5 CRUD routes
- **Artisan-style CLI** — `dart run shelfbase make:resource User` scaffolds a complete feature slice
- **Shelf-native** — produces a standard Shelf `Handler`; any Shelf middleware works

---

## Quick start

```dart
// main.dart
import 'package:shelfbase/shelfbase.dart';

void main() async {
  final app = Application();

  // Register services
  app.singleton<UserService>((_) => UserService());

  // Global middleware
  app.use(LogMiddleware());

  // Routes
  app.router.get('/health', (req) => Response.json({'status': 'ok'}));

  app.router.group(
    prefix: '/api/v1',
    middleware: [AuthMiddleware()],
    routes: (r) {
      r.resource('/users', UserController(app.make<UserService>()));
    },
  );

  await app.listen(port: 3000);
}
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
    │   ├── route.dart           ← Route value object with tryMatch / name / url
    │   ├── route_pattern.dart   ← RegExp-based URL matching and param extraction
    │   └── router.dart          ← Router + ResourceController
    ├── middleware/
    │   ├── middleware.dart      ← Middleware interface + Next typedef
    │   └── pipeline.dart        ← Pipeline.run(middleware, request, handler)
    └── support/
        ├── service_provider.dart ← ServiceProvider abstract (register + boot)
        └── helpers.dart          ← app() / make<T>() / route(name) / env(key)
```

### Layer responsibilities

| Layer | What it does |
|---|---|
| **Application** | Owns the container, router, global middleware, and HTTP server |
| **Container** | Lazy singleton / transient factory registry; no reflection |
| **Router** | First-match flat route list; regex named-group URL matching |
| **Middleware** | Composable pipeline applied globally, per-group, or per-route |
| **Request** | Wraps Shelf request; caches body; exposes ergonomic accessors |
| **Response** | Immutable value object; serialises to Shelf response via `toShelf()` |
| **ServiceProvider** | Two-phase boot: `register` binds services, `boot` starts them |

---

## Developer guide

### 1 — Write a service

```dart
class UserService {
  final _users = <String, Map<String, dynamic>>{};

  List<Map<String, dynamic>> findAll() => _users.values.toList();

  Map<String, dynamic>? findOne(String id) => _users[id];

  Map<String, dynamic> create(String name, String email) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return _users[id] = {'id': id, 'name': name, 'email': email};
  }
}
```

### 2 — Write a controller

For manually registered routes, any class or function works:

```dart
class UserController extends ResourceController {
  final UserService _service;
  UserController(this._service);

  @override
  Response index(Request request) {
    final page = int.tryParse(request.query('page') ?? '1') ?? 1;
    return Response.json({'data': _service.findAll(), 'page': page});
  }

  @override
  Response show(Request request) {
    final user = _service.findOne(request.param('id'));
    return user != null
        ? Response.json(user)
        : Response.notFound('User not found');
  }

  @override
  Future<Response> store(Request request) async {
    final body = await request.jsonMap();
    final name = body['name'] as String?;
    final email = body['email'] as String?;
    if (name == null || email == null) {
      return Response.unprocessable({'name': ['required'], 'email': ['required']});
    }
    return Response.created(_service.create(name, email));
  }

  @override
  Future<Response> update(Request request) async {
    final body = await request.jsonMap();
    final user = _service.update(request.param('id'), body);
    return user != null ? Response.json(user) : Response.notFound('Not found');
  }

  @override
  Response destroy(Request request) {
    final removed = _service.delete(request.param('id'));
    return removed ? Response.noContent() : Response.notFound('Not found');
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

### 3 — Register services with a provider

```dart
class AppServiceProvider extends ServiceProvider {
  @override
  void register() {
    // bind<T> → new instance per make(); singleton<T> → shared instance
    app.singleton<UserService>((_) => UserService());
  }

  @override
  Future<void> boot() async {
    // Runs after all providers are registered — safe to call app.make<T>() here
  }
}
```

### 4 — Compose and boot

```dart
void main() async {
  final app = Application();

  app.register(AppServiceProvider());
  app.use(LogMiddleware());

  app.router.resource('/users', UserController(app.make<UserService>()));

  await app.listen(port: 3000);
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

// Override in tests
app.rebind<MyService>((_) => FakeMyService());

// Check if bound
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
app.router.any('/path', handler);   // matches any HTTP method
```

### Route parameters

Parameters are declared with `<name>` in the path and read via `request.param('name')`:

```dart
app.router.get('/users/<id>', (req) {
  return Response.json({'id': req.param('id')});
});
```

### Named routes and URL generation

```dart
app.router.get('/users/<id>', handler).name('users.show');

// Later, generate the URL
final url = route('users.show', {'id': '42'}); // → /users/42
```

### Route groups

```dart
app.router.group(
  prefix: '/api/v1',
  middleware: [AuthMiddleware()],
  routes: (r) {
    r.resource('/users', UserController());

    r.group(prefix: '/admin', middleware: [AdminMiddleware()], routes: (r) {
      r.get('/stats', StatsController.show);
    });
  },
);
```

### Prefix shorthand

```dart
app.router.prefix('/api/v1').group((r) {
  r.get('/users', UserController.index);
});
```

---

## Middleware

Implement the `Middleware` interface:

```dart
class AuthMiddleware implements Middleware {
  @override
  Future<Response> handle(Request request, Next next) async {
    final token = request.bearerToken;
    if (token == null) return Response.unauthorized();
    return next(request);  // pass to the next middleware or handler
  }
}
```

Apply globally, per-group, or per-route:

```dart
// Global — every request
app.use(LogMiddleware());

// Per group
app.router.group(middleware: [AuthMiddleware()], routes: (r) { ... });
```

---

## Request API

```dart
// Route parameters  (/<id>)
request.param('id')

// Query string  (?page=2)
request.query('page')
request.queryAll         // Map<String, String>

// Headers
request.header('content-type')
request.authorization    // Authorization header value
request.bearerToken      // Bearer <token> extracted

// Body
await request.body()     // raw String (cached)
await request.json()     // decoded dynamic
await request.jsonMap()  // Map<String, dynamic>
await request.input('name')  // single JSON key
await request.form()     // URL-encoded form fields

// Meta
request.method           // 'GET', 'POST', …
request.path             // '/users/42'
request.uri              // full Uri
request.isJson           // content-type check
request.ip               // best-effort client IP
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

// Chain headers
Response.json(data).withHeader('X-Request-Id', id)
Response.json(data).withStatus(202)
```

---

## Helper functions

```dart
import 'package:shelfbase/shelfbase.dart';

app()              // the Application singleton
make<T>()          // shorthand for app().make<T>()
route('name')      // URL for a named route (no params)
route('name', {'id': '42'})   // URL with params
env('DATABASE_URL')            // read environment variable
env('PORT', fallback: '3000')  // with fallback
envInt('PORT', fallback: 3000) // parsed as int
```

---

## How ShelfBase compares

| | Raw Shelf | ShelfBase |
|---|---|---|
| Routing | Manual `shelf_router` setup | Fluent `router.get/post/resource/group` |
| DI | None | IoC container — `bind / singleton / make` |
| Middleware | Shelf pipeline | Composable, stackable middleware classes |
| Organisation | Ad-hoc | Service providers + resource controllers |
| Bootstrapping | `shelf_io.serve(handler, …)` | `Application().listen()` |

### Laravel concept mapping

| Laravel | ShelfBase |
|---|---|
| `Route::get('/path', fn)` | `app.router.get('/path', handler)` |
| `Route::resource('users', UserController)` | `router.resource('/users', UserController())` |
| `Route::group(['prefix' => '/api', 'middleware' => [AuthMiddleware::class]], fn)` | `router.group(prefix: '/api', middleware: [AuthMiddleware()], routes: (r) {...})` |
| `ServiceProvider::register()` / `boot()` | `ServiceProvider.register()` / `boot()` |
| `app()->bind(...)` | `app.bind<T>(...)` |
| `app()->singleton(...)` | `app.singleton<T>(...)` |
| `app()->make(T::class)` | `app.make<T>()` |
| `$request->param('id')` | `request.param('id')` |
| `$request->query('page')` | `request.query('page')` |
| `response()->json(data)` | `Response.json(data)` |

---

## Roadmap

### Phase 1 — MVP ✅ (current)
- `Application` class with IoC container, router, and HTTP server
- `Container` — `bind / singleton / instance / make / rebind`
- `ServiceProvider` — `register()` + `boot()` lifecycle
- `Router` — verb methods, `resource`, nested `group`, named routes, URL generation
- Custom regex URL matching — no `shelf_router` dependency
- `Middleware` interface + composable `Pipeline`
- `Request` wrapper — params, query, headers, body, cached parsing
- `Response` value object — full set of factory helpers
- `ResourceController` abstract class
- **`shelfbase` CLI** — `make:controller | make:service | make:middleware | make:provider | make:resource`
  - Suffix stripping (`UserController` → generates `UserController` class)
  - `--flat`, `--dry-run` (`-d`), `--force` (`-f`), `--path` (`-p`) flags
  - SKIP guard on existing files
- 61 unit tests

### Phase 2 — Code generation
- `shelfbase_generator` package using `build_runner` + `source_gen`
- Reads annotations at build time, generates binding registration code
- Eliminates manual `singleton<T>` and factory wiring in providers

### Phase 3 — Guards, interceptors, pipes
- `Guard` interface — pre-handler authorisation checks
- `Interceptor` — pre/post handler transform
- `ExceptionFilter` — structured error response handling
- `Pipe` — request body validation and transformation
- Global registration via `app.useGlobalGuard(…)` etc.

### Phase 4 — Production readiness
- Scoped providers (request-scoped singletons)
- Graceful shutdown hooks
- Health check builder
- `pub.dev` packaging (`shelfbase` + `shelfbase_generator`)
- Full API documentation site

---

## CLI — `make:*` generators

ShelfBase ships a `shelfbase` executable that scaffolds files from templates,
exactly like Laravel's `php artisan make:*`.

### Installation

```yaml
# pubspec.yaml
dev_dependencies:
  shelfbase:
    path: /path/to/shelfbase   # or git/pub.dev when published
```

### Commands

| Command | What it creates |
|---|---|
| `make:controller <Name>` | `<name>.controller.dart` with CRUD stubs |
| `make:service <Name>` | `<name>.service.dart` with CRUD stubs |
| `make:middleware <Name>` | `<name>.middleware.dart` |
| `make:provider <Name>` | `<name>.provider.dart` |
| `make:module <Name>` | `<name>.module.dart` registration function |
| `make:resource <Name>` | All three files (service + controller + module), wired together |

Names are normalised — `UserController`, `user-controller`, and `user_controller` all produce the same output. Suffixes are stripped automatically: `make:controller UserController` generates a class named `UserController`, not `UserControllerController`.

### Options

| Flag | Short | Description |
|---|---|---|
| `--dry-run` | `-d` | Preview output without writing files |
| `--force` | `-f` | Overwrite existing files |
| `--flat` | | Write directly to `lib/` without a subdirectory |
| `--path <dir>` | `-p` | Write into `lib/<dir>/` instead of `lib/<name>/` |
| `--no-service` | | (controller only) Skip service import |

### Examples

```bash
# Full CRUD slice — creates lib/users/{users.service,users.controller,users.module}.dart
dart run shelfbase make:resource User

# Nested path
dart run shelfbase make:resource Order --path api/v1/orders

# Standalone middleware
dart run shelfbase make:middleware Auth

# Preview without writing
dart run shelfbase make:resource Payment --dry-run

# Overwrite existing files
dart run shelfbase make:resource User --force
```

### Generated output (example: `make:resource User`)

```
  CREATE  lib/users/users.service.dart
  CREATE  lib/users/users.controller.dart
  CREATE  lib/users/users.module.dart
```

`users.module.dart` exports a `registerUsersModule(Application app)` function —
call it in `main.dart` to bind the service and register routes.

---

## Running the example

```bash
cd example
dart pub get
dart run lib/main.dart
```

Then:

```bash
# Public endpoints
curl http://localhost:3000/health
curl http://localhost:3000/

# Authenticated API (add Bearer token)
curl http://localhost:3000/api/v1/users \
     -H 'Authorization: Bearer secret-token'

curl http://localhost:3000/api/v1/users/1 \
     -H 'Authorization: Bearer secret-token'

curl -X POST http://localhost:3000/api/v1/users \
     -H 'Authorization: Bearer secret-token' \
     -H 'Content-Type: application/json' \
     -d '{"name":"Alice","email":"alice@example.com"}'

curl -X DELETE http://localhost:3000/api/v1/users/1 \
     -H 'Authorization: Bearer secret-token'
```

---

## Running tests

```bash
dart test
```

---

## Design philosophy

> "Simple by default, extensible when you need it."

- **No reflection** — works with AOT (Flutter, Dart Native). No `dart:mirrors`, no runtime scanning.
- **Explicit over magic** — Phase 1 wiring is deliberate. You see exactly what the framework does.
- **Incremental evolution** — each phase adds power without breaking the previous API.
- **Laravel concepts, Dart idioms** — we borrow the *architecture* from Laravel, not the *syntax*.
- **Shelf-native** — ShelfBase produces a standard Shelf `Handler`. Mix it with any Shelf middleware.
