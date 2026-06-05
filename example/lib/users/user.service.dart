/// A simple in-memory user service.
///
/// In a real app this would talk to a database.  ShelfBase registers it as a
/// singleton provider and injects it into [UserController].
class UserService {
  final List<Map<String, dynamic>> _store = [
    {'id': '1', 'name': 'Alice', 'email': 'alice@example.com'},
    {'id': '2', 'name': 'Bob', 'email': 'bob@example.com'},
  ];

  List<Map<String, dynamic>> findAll() => List.unmodifiable(_store);

  Map<String, dynamic>? findOne(String id) {
    try {
      return _store.firstWhere((u) => u['id'] == id);
    } on StateError {
      return null;
    }
  }

  Map<String, dynamic> create(String name, String email) {
    final user = {
      'id': (_store.length + 1).toString(),
      'name': name,
      'email': email,
    };
    _store.add(user);
    return user;
  }

  bool delete(String id) {
    final index = _store.indexWhere((u) => u['id'] == id);
    if (index == -1) return false;
    _store.removeAt(index);
    return true;
  }
}
