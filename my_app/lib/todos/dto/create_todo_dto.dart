import '../../validation/validator.dart';

/// Validated payload for POST /todos.
class CreateTodoDto {
  final String title;
  final String? description;

  const CreateTodoDto({required this.title, this.description});

  factory CreateTodoDto.fromMap(Map<String, dynamic> data) {
    Validator(data)
      ..required('title')
      ..isString('title')
      ..minLength('title', 3)
      ..maxLength('title', 200)
      ..isString('description')
      ..maxLength('description', 1000)
      ..validate();

    return CreateTodoDto(
      title: (data['title'] as String).trim(),
      description: data['description'] != null
          ? (data['description'] as String).trim()
          : null,
    );
  }
}
