# ShelfBase

> NestJS-inspired backend framework for Dart, built on top of [Shelf](https://pub.dev/packages/shelf).

ShelfBase is **not** a thin wrapper around Shelf — it is a structured framework layer that gives you:

- **Modular architecture** — group controllers and services into self-contained modules
- **Constructor-injected dependency injection** — explicit factory-based DI container (no mirrors, AOT-safe)
- **Controller + route declaration** — pair `@Controller`/`@Get`/`@Post` annotations with an explicit route list
- **Clean public API** — one import, then you're productive
- **Shelf compatibility** — uses Shelf under the hood; any Shelf middleware works
- **Code generator CLI** — `shelfbase generate resource users` scaffolds a complete feature slice

---

## Quick start

```dart
// main.dart
import 'package:shelfbase/shelfbase.dart';
import 'app.module.dart';

void main() async {
  final app = ShelfBase.create(AppModule());
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
    │   ├── app.dart             ← ShelfBase (factory) + ShelfBaseApp (listen/close)
    │   └── shelf_adapter.dart   ← converts RouteRegistry → Shelf Handler
    ├── decorators/
    │   ├── controller.dart      ← @Controller annotation
    │   ├── http_methods.dart    ← @Get @Post @Put @Delete @Patch
    │   └── module_annotation.dart ← @Module annotation
    ├── di/
    │   ├── container.dart       ← DIContainer (register / resolve / override)
    │   └── provider.dart        ← Provider<T> (simple + withDeps factories)
    ├── http/
    │   └── response_builder.dart ← Res.ok() Res.created() Res.notFound() …
    ├── modules/
    │   ├── shelf_base_module.dart     ← abstract ShelfBaseModule
    │   ├── shelf_base_controller.dart ← abstract ShelfBaseController
    │   ├── controller_factory.dart    ← ControllerFactory<T>
    │   └── module_loader.dart         ← wires DI + routes, depth-first
    └── router/
        ├── route_entry.dart     ← RouteEntry (method + path + handler)
        └── route_registry.dart  ← accumulates routes from controllers
```

### Layer responsibilities

| Layer | What it does |
|---|---|
| **Core** | Bootstraps the server, assembles the Shelf pipeline |
| **Router** | Normalises and accumulates route records |
| **DI** | Singleton-by-default factory container; no reflection |
| **Modules** | Unit of organisation — groups providers + controllers |
| **Decorators** | Cosmetic annotations (document intent; drive codegen in Phase 2) |
| **HTTP utils** | `Res.*` helpers for common response shapes |

---

## Developer guide

### 1 — Write a service

```dart
class UserService {
  List<Map<String, dynamic>> findAll() => [...];
  Map<String, dynamic>? findOne(String id) => ...;
}
```

### 2 — Write a controller

```dart
@Controller('/users')
class UserController extends ShelfBaseController {
  final UserService _service;
  UserController(this._service);

  @override
  String get prefix => '/users';

  @override
  List<RouteEntry> get routes => [
    RouteEntry.get('/',      _getAll),
    RouteEntry.get('/<id>', _getOne),   // id passed as positional arg
    RouteEntry.post('/',     _create),
  ];

  @Get('/')
  Response _getAll(Request req) => Res.ok(_service.findAll());

  @Get('/<id>')
  Response _getOne(Request req, String id) {
    final user = _service.findOne(id);
    return user != null ? Res.ok(user) : Res.notFound('User $id not found');
  }

  @Post('/')
  Future<Response> _create(Request req) async {
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    return Res.created(_service.create(body['name'], body['email']));
  }
}
```

**Path parameter note** — shelf_router passes named URL segments (e.g. `<id>`) as positional arguments after `Request`. Match your handler signature to the route pattern, or use `request.params['id']` if you prefer to keep every handler `(Request) → Response`.

### 3 — Declare a module

```dart
@Module(controllers: [UserController], providers: [UserService])
class UserModule extends ShelfBaseModule {
  @override
  List<Provider<dynamic>> get providers => [
    Provider<UserService>(() => UserService()),
  ];

  @override
  List<ControllerFactory<dynamic>> get controllers => [
    ControllerFactory<UserController>(
      (c) => UserController(c.get<UserService>()),
    ),
  ];
}
```

### 4 — Compose the root module

```dart
class AppModule extends ShelfBaseModule {
  @override
  List<ShelfBaseModule> get imports => [UserModule()];
}
```

### 5 — Boot

```dart
void main() async {
  final app = ShelfBase.create(AppModule());
  await app.listen(port: 3000);
}
```

---

## Dependency injection

The `DIContainer` is a simple, AOT-safe factory registry.

```dart
// Register
container.register<MyService>((_) => MyService(), singleton: true);

// Resolve
final svc = container.get<MyService>();

// Override (useful in tests)
container.override<MyService>((_) => FakeMyService());
```

`Provider<T>` wraps registration for use inside modules:

```dart
// No dependencies
Provider<UserService>(() => UserService())

// With dependencies resolved from the container
Provider<OrderService>.withDeps((c) => OrderService(c.get<UserService>()))
```

---

## Response helpers (`Res`)

```dart
Res.ok({'users': users})          // 200 application/json
Res.created({'id': newId})        // 201
Res.noContent()                   // 204
Res.badRequest('name is required') // 400
Res.unauthorized()                 // 401
Res.forbidden()                    // 403
Res.notFound('User not found')     // 404
Res.serverError()                  // 500
```

---

## How ShelfBase differs from raw Shelf

| | Raw Shelf | ShelfBase |
|---|---|---|
| Routing | Manual `shelf_router` setup | Declared in controller classes |
| DI | None | Explicit factory container |
| Organisation | Single handler or ad-hoc | Modules → Controllers → Services |
| Middleware | Pipeline | Same Shelf pipeline (fully compatible) |
| Bootstrapping | `shelf_io.serve(handler, …)` | `ShelfBase.create(module).listen()` |

### How ShelfBase mirrors NestJS

| NestJS | ShelfBase (Phase 1) |
|---|---|
| `@Module({controllers, providers})` | Extend `ShelfBaseModule`, override getters |
| `@Controller('/path')` | Cosmetic annotation + `get prefix => '/path'` |
| `@Get('/')` | Cosmetic annotation + explicit `RouteEntry.get` |
| `@Injectable()` service | `Provider<T>(() => T())` in module |
| Constructor injection | `ControllerFactory<T>((c) => T(c.get<Dep>()))` |
| `NestFactory.create(AppModule)` | `ShelfBase.create(AppModule())` |

The Phase 1 gap (explicit factories vs magic reflection) will be closed by the source_gen code generator in Phase 2.

---

## Roadmap

### Phase 1 — MVP ✅ (current)
- Shelf adapter + request pipeline
- `DIContainer` with singleton support
- `ShelfBaseModule` / `ShelfBaseController` base classes
- `ControllerFactory` explicit wiring
- `RouteRegistry` + path normalisation
- Cosmetic `@Controller` / `@Get` / `@Post` / … annotations
- `Res.*` response helpers
- Request logger middleware
- **`shelfbase` CLI** — `generate module | service | controller | resource`
  - Subdirectory paths (`api/v1/orders`)
  - PascalCase / kebab-case / snake_case input normalisation
  - `--flat`, `--dry-run`, `--force`, `--no-service` flags
  - SKIP guard on existing files
- 27 unit tests

### Phase 2 — Code generation (eliminating boilerplate)
- `shelfbase_generator` package using `build_runner` + `source_gen`
- Reads `@Module`, `@Controller`, `@Get`, `@Post`, … annotations at **build time**
- Generates `*.shelfbase.dart` files with `Provider` + `ControllerFactory` registrations
- Developer only writes annotations; no manual factory wiring needed
- `@Injectable()` support for transitive provider discovery

### Phase 3 — Middleware system
- `Guard` interface (pre-handler authorisation check)
- `Interceptor` interface (pre/post handler transform — like NestJS interceptors)
- `ExceptionFilter` for structured error responses
- `Pipe` interface for request body validation/transformation
- Global guard/interceptor registration via `app.useGlobalGuard(…)`

### Phase 4 — Production readiness
- `@Param`, `@Body`, `@Query`, `@Headers` parameter decorators (via codegen)
- Scoped providers (request-scoped singletons)
- Graceful shutdown hooks
- Health check endpoint builder
- `pub.dev` packaging (`shelfbase` + `shelfbase_generator`)
- Full API documentation site

---

## CLI — code generator

ShelfBase ships a `shelfbase` executable that scaffolds files from templates,
exactly like `nest generate` in NestJS.

### Installation (from your project)

```yaml
# pubspec.yaml
dev_dependencies:
  shelfbase:
    path: /path/to/shelfbase   # or git/pub.dev when published
```

Then run commands with:

```bash
dart run shelfbase:shelfbase <command> [options]
```

### Commands

| Command | Alias | What it creates |
|---|---|---|
| `generate module <name>` | `g m` | Bare `<name>.module.dart` |
| `generate service <name>` | `g s` | `<name>.service.dart` with CRUD stubs |
| `generate controller <name>` | `g c` | `<name>.controller.dart` with 5 CRUD routes |
| `generate resource <name>` | `g r` / `g res` | All three files wired together |

### Examples

```bash
# Full CRUD slice — creates lib/users/{users.service,users.controller,users.module}.dart
dart run shelfbase:shelfbase generate resource users

# Nested path — creates lib/api/v1/orders/{...}
dart run shelfbase:shelfbase g resource api/v1/orders

# PascalCase or kebab-case input — both work
dart run shelfbase:shelfbase g resource UserProfile
dart run shelfbase:shelfbase g resource user-profile

# Standalone controller with no service import
dart run shelfbase:shelfbase g controller health --no-service

# Flat mode — writes directly to lib/ without creating a subdirectory
dart run shelfbase:shelfbase g service auth --flat

# Preview without writing (dry-run)
dart run shelfbase:shelfbase g resource payments --dry-run

# Overwrite existing files
dart run shelfbase:shelfbase g resource users --force
```

### Generated output (example: `g resource users`)

```
  CREATE  lib/users/users.service.dart    (526 bytes)
  CREATE  lib/users/users.controller.dart (1355 bytes)
  CREATE  lib/users/users.module.dart     (566 bytes)
```

`users.module.dart` is fully wired — the service is registered as a provider
and the controller factory receives it via `c.get<UsersService>()`.
Import it into your `AppModule.imports` and the routes are live.

---

## Running the example

```bash
cd example
dart pub get
dart run lib/main.dart
```

Then:

```bash
curl http://localhost:3000/users
curl http://localhost:3000/users/1
curl -X POST http://localhost:3000/users \
     -H 'content-type: application/json' \
     -d '{"name":"Carol","email":"carol@example.com"}'
curl -X DELETE http://localhost:3000/users/1
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
- **Explicit over magic** — Phase 1 wiring is verbose on purpose. You see exactly what the framework does.
- **Incremental evolution** — each phase adds power without breaking the previous API.
- **NestJS concepts, Dart idioms** — we borrow the *architecture* from NestJS, not the *syntax*.
- **Shelf-native** — ShelfBase produces a standard Shelf `Handler`. You can mix it with any Shelf middleware.
