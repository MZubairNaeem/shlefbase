import 'package:shelfbase/shelfbase.dart';

import '../todos/todo_controller.dart';

/// All API routes, Laravel-style.
///
/// Each route delegates to a controller method resolved from the IoC container:
///   use<ControllerType>((c) => c.methodName)
///
/// This mirrors Laravel's `[Controller::class, 'method']` syntax —
/// the controller is constructed once (singleton) and method tearoffs
/// are used as route handlers.
void registerApiRoutes(Router r) {
  r.group(
    prefix: '/api',
    routes: (r) {
      // ── Todos ──────────────────────────────────────────────────────────────
      // GET    /api/todos             → TodoController@index
      // POST   /api/todos             → TodoController@store
      // GET    /api/todos/<id>        → TodoController@show
      // PUT    /api/todos/<id>        → TodoController@update
      // PATCH  /api/todos/<id>        → TodoController@update
      // DELETE /api/todos/<id>        → TodoController@destroy
      r.get('/todos',           use<TodoController>((c) => c.index));
      r.post('/todos',          use<TodoController>((c) => c.store));
      r.get('/todos/<id>',      use<TodoController>((c) => c.show));
      r.put('/todos/<id>',      use<TodoController>((c) => c.update));
      r.patch('/todos/<id>',    use<TodoController>((c) => c.update));
      r.delete('/todos/<id>',   use<TodoController>((c) => c.destroy));
    },
  );
}
