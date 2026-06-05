import 'package:shelfbase/shelfbase.dart';

import '../database/migration_runner.dart';
import '../database/migration_store.dart';
import 'migrations/create_todos_table.dart';
import 'todo_controller.dart';
import 'todo_service.dart';

class TodoProvider extends ServiceProvider {
  late final MigrationStore _store;

  @override
  void register() {
    _store = MigrationStore();

    // Migrations run synchronously here so the table exists before any
    // make<TodoService>() call during route wiring in main().
    MigrationRunner.run([CreateTodosTable()], _store);

    this.app.instance<MigrationStore>(_store);
    this.app.singleton<TodoService>((_) => TodoService(_store.table('todos')!));
    this.app.singleton<TodoController>((c) => TodoController(c.make<TodoService>()));
  }
}
