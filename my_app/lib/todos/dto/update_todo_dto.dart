import '../../validation/validator.dart';
import '../../validation/validation_exception.dart';

/// Validated payload for PUT/PATCH /todos/:id.
///
/// At least one field must be present.
class UpdateTodoDto {
  final String? title;
  final String? description;
  final bool? completed;

  const UpdateTodoDto({this.title, this.description, this.completed});

  factory UpdateTodoDto.fromMap(Map<String, dynamic> data) {
    Validator(data)
      ..isString('title')
      ..minLength('title', 3)
      ..maxLength('title', 200)
      ..isString('description')
      ..maxLength('description', 1000)
      ..isBool('completed')
      ..validate();

    final hasTitle = data.containsKey('title');
    final hasDescription = data.containsKey('description');
    final hasCompleted = data.containsKey('completed');

    if (!hasTitle && !hasDescription && !hasCompleted) {
      throw ValidationException({
        'body': ['At least one field (title, description, completed) is required.'],
      });
    }

    return UpdateTodoDto(
      title: hasTitle ? (data['title'] as String).trim() : null,
      description: hasDescription
          ? (data['description'] as String?)?.trim()
          : null,
      completed: hasCompleted ? data['completed'] as bool : null,
    );
  }
}
