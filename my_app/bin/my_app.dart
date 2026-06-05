import 'package:shelfbase/shelfbase.dart';

import 'package:my_app/middleware/json_middleware.dart';
import 'package:my_app/middleware/log_middleware.dart';
import 'package:my_app/middleware/validate_middleware.dart';
import 'package:my_app/routes/api.dart';
import 'package:my_app/todos/todo_provider.dart';

void main() async {
  final application = Application();

  // ── Service providers ────────────────────────────────────────────────────
  application.register(TodoProvider());

  // ── Global middleware ────────────────────────────────────────────────────
  application
    ..use(LogMiddleware())       // log every request
    ..use(JsonMiddleware())      // 400 on non-JSON mutating requests
    ..use(ValidateMiddleware()); // 422 on ValidationException

  // ── Routes ───────────────────────────────────────────────────────────────
  application.router.get(
    '/',
    (req) => Response.json({
      'app': 'ShelfBase Todo API',
      'version': '1.0.0',
      'endpoints': {
        'GET    /api/todos': 'List todos (?completed=bool&page=int&per_page=int)',
        'GET    /api/todos/:id': 'Get a todo',
        'POST   /api/todos': 'Create a todo',
        'PUT    /api/todos/:id': 'Replace a todo',
        'PATCH  /api/todos/:id': 'Partially update a todo',
        'DELETE /api/todos/:id': 'Delete a todo',
      },
    }),
  ).name('home');

  // All API routes are declared in lib/routes/api.dart.
  registerApiRoutes(application.router);

  // ── Start ────────────────────────────────────────────────────────────────
  await application.listen(port: 8080);
}
