import 'dto/create_todo_dto.dart';
import 'dto/update_todo_dto.dart';
import 'todo_model.dart';

class TodoService {
  final List<Map<String, dynamic>> _todos;

  TodoService(this._todos);

  // ── Queries ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> findAll({
    bool? completed,
    int page = 1,
    int perPage = 10,
  }) {
    final filtered = _todos.where((t) {
      if (completed != null) return t['completed'] == completed;
      return true;
    }).toList();

    final offset = (page - 1) * perPage;
    return filtered.skip(offset).take(perPage).toList();
  }

  int count({bool? completed}) => _todos.where((t) {
        if (completed != null) return t['completed'] == completed;
        return true;
      }).length;

  Map<String, dynamic>? findById(String id) {
    try {
      return _todos.firstWhere((t) => t['id'] == id);
    } on StateError {
      return null;
    }
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Map<String, dynamic> create(CreateTodoDto dto) {
    final todo = Todo.create(
      title: dto.title,
      description: dto.description,
    );
    final map = todo.toMap();
    _todos.add(map);
    return map;
  }

  Map<String, dynamic>? update(String id, UpdateTodoDto dto) {
    final index = _todos.indexWhere((t) => t['id'] == id);
    if (index == -1) return null;

    final existing = Todo.fromMap(_todos[index]);
    final updated = existing.copyWith(
      title: dto.title,
      description: dto.description,
      completed: dto.completed,
    );

    final map = updated.toMap();
    _todos[index] = map;
    return map;
  }

  bool delete(String id) {
    final index = _todos.indexWhere((t) => t['id'] == id);
    if (index == -1) return false;
    _todos.removeAt(index);
    return true;
  }
}
