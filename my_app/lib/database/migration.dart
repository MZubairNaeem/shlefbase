import 'migration_store.dart';

/// Base class for schema migrations.
///
/// Implement [up] to create/alter tables and [down] to roll back.
abstract class Migration {
  String get name;

  void up(MigrationStore store);
  void down(MigrationStore store);
}
