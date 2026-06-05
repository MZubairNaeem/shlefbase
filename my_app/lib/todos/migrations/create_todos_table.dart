import '../../database/migration.dart';
import '../../database/migration_store.dart';
import '../todo_model.dart';

/// Creates the `todos` table and seeds it with sample data.
class CreateTodosTable extends Migration {
  @override
  String get name => '2024_01_01_000000_create_todos_table';

  @override
  void up(MigrationStore store) {
    store.createTable(
      'todos',
      rows: [
        Todo.create(
          title: 'Buy groceries',
          description: 'Milk, eggs, bread, and coffee',
        ).toMap(),
        Todo.create(
          title: 'Read a book',
          description: 'Finish "Clean Code" by Robert Martin',
        ).toMap(),
        Todo.create(
          title: 'Go for a run',
        ).toMap(),
      ],
    );
  }

  @override
  void down(MigrationStore store) {
    store.dropTable('todos');
  }
}
