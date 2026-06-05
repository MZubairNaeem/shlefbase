import 'package:shelfbase/shelfbase.dart';

import 'dto/create_todo_dto.dart';
import 'dto/update_todo_dto.dart';
import 'todo_service.dart';

class TodoController extends ResourceController {
  final TodoService _service;

  TodoController(this._service);

  /// GET /todos?completed=true&page=1&per_page=10
  @override
  Response index(Request req) {
    final completedParam = req.query('completed');
    final bool? completed = completedParam == null
        ? null
        : completedParam.toLowerCase() == 'true';

    final page = int.tryParse(req.query('page') ?? '1') ?? 1;
    final perPage = int.tryParse(req.query('per_page') ?? '10') ?? 10;

    final todos = _service.findAll(
      completed: completed,
      page: page,
      perPage: perPage,
    );

    return Response.json({
      'data': todos,
      'meta': {
        'page': page,
        'per_page': perPage,
        'total': _service.count(completed: completed),
      },
    });
  }

  /// GET /todos/:id
  @override
  Response show(Request req) {
    final id = req.param('id');
    final todo = _service.findById(id);
    if (todo == null) return Response.notFound('Todo not found.');
    return Response.json({'data': todo});
  }

  /// POST /todos
  @override
  Future<Response> store(Request req) async {
    final body = await req.jsonMap();
    final dto = CreateTodoDto.fromMap(body);
    final todo = _service.create(dto);
    return Response.created({'data': todo});
  }

  /// PUT/PATCH /todos/:id
  @override
  Future<Response> update(Request req) async {
    final id = req.param('id');
    if (_service.findById(id) == null) return Response.notFound('Todo not found.');

    final body = await req.jsonMap();
    final dto = UpdateTodoDto.fromMap(body);
    final todo = _service.update(id, dto);
    return Response.json({'data': todo});
  }

  /// DELETE /todos/:id
  @override
  Response destroy(Request req) {
    final id = req.param('id');
    final deleted = _service.delete(id);
    if (!deleted) return Response.notFound('Todo not found.');
    return Response.noContent();
  }
}
