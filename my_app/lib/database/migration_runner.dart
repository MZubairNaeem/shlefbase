import 'migration.dart';
import 'migration_store.dart';

/// Runs a list of migrations in order.
class MigrationRunner {
  static void run(List<Migration> migrations, MigrationStore store) {
    for (final migration in migrations) {
      migration.up(store);
      print('[Migration] Ran: ${migration.name}');
    }
  }

  static void rollback(List<Migration> migrations, MigrationStore store) {
    for (final migration in migrations.reversed) {
      migration.down(store);
      print('[Migration] Rolled back: ${migration.name}');
    }
  }
}
