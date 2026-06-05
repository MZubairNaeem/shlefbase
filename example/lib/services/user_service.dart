class UserService {
  final List<Map<String, dynamic>> _store = [
    {'id': '1', 'name': 'Alice', 'email': 'alice@example.com', 'role': 'admin'},
    {'id': '2', 'name': 'Bob', 'email': 'bob@example.com', 'role': 'user'},
  ];

  List<Map<String, dynamic>> findAll({int page = 1, int perPage = 10}) {
    final start = (page - 1) * perPage;
    return _store.skip(start).take(perPage).toList();
  }

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
      'role': 'user',
    };
    _store.add(user);
    return user;
  }

  Map<String, dynamic>? update(String id, Map<String, dynamic> data) {
    final index = _store.indexWhere((u) => u['id'] == id);
    if (index == -1) return null;
    _store[index] = {..._store[index], ...data, 'id': id};
    return _store[index];
  }

  bool delete(String id) {
    final index = _store.indexWhere((u) => u['id'] == id);
    if (index == -1) return false;
    _store.removeAt(index);
    return true;
  }
}
