/// In-memory "database" that holds tables as lists of row maps.
///
/// Shared across all services through the IoC container. Tables are
/// created by migrations before the server starts.
class MigrationStore {
  final Map<String, List<Map<String, dynamic>>> _tables = {};

  /// Creates a table. Optionally seeds it with initial [rows].
  void createTable(String name, {List<Map<String, dynamic>> rows = const []}) {
    if (_tables.containsKey(name)) return;
    _tables[name] = List.of(rows);
  }

  /// Drops a table (used in rollbacks).
  void dropTable(String name) => _tables.remove(name);

  /// Returns the live row list for [name], or `null` if the table doesn't exist.
  List<Map<String, dynamic>>? table(String name) => _tables[name];

  bool hasTable(String name) => _tables.containsKey(name);
}
