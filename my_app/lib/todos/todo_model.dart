import 'dart:math';

/// Represents a single todo item.
class Todo {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Todo({
    required this.id,
    required this.title,
    this.description,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Todo.create({required String title, String? description}) {
    final now = DateTime.now().toUtc();
    return Todo(
      id: _generateId(),
      title: title,
      description: description,
      completed: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        completed: map['completed'] as bool,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Todo copyWith({
    String? title,
    String? description,
    bool? completed,
  }) =>
      Todo(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        completed: completed ?? this.completed,
        createdAt: createdAt,
        updatedAt: DateTime.now().toUtc(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'completed': completed,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

String _generateId() {
  final rng = Random();
  final hex = List.generate(32, (_) => rng.nextInt(16).toRadixString(16)).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}'
      '-4${hex.substring(13, 16)}-${hex.substring(16, 20)}'
      '-${hex.substring(20, 32)}';
}
