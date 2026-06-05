import 'validation_exception.dart';

/// Fluent, field-by-field validator for JSON request bodies.
///
/// Usage:
/// ```dart
/// Validator(data)
///   ..required('title')
///   ..maxLength('title', 200)
///   ..optional('description', (v) => v is String)
///   ..validate();
/// ```
class Validator {
  final Map<String, dynamic> _data;
  final Map<String, List<String>> _errors = {};

  Validator(this._data);

  // ── Rules ─────────────────────────────────────────────────────────────────

  Validator required(String field, {String? message}) {
    final value = _data[field];
    if (value == null || (value is String && value.trim().isEmpty)) {
      _addError(field, message ?? 'The $field field is required.');
    }
    return this;
  }

  Validator isString(String field, {String? message}) {
    final value = _data[field];
    if (value != null && value is! String) {
      _addError(field, message ?? 'The $field field must be a string.');
    }
    return this;
  }

  Validator isBool(String field, {String? message}) {
    final value = _data[field];
    if (value != null && value is! bool) {
      _addError(field, message ?? 'The $field field must be a boolean.');
    }
    return this;
  }

  Validator minLength(String field, int min, {String? message}) {
    final value = _data[field];
    if (value is String && value.trim().length < min) {
      _addError(
        field,
        message ?? 'The $field field must be at least $min characters.',
      );
    }
    return this;
  }

  Validator maxLength(String field, int max, {String? message}) {
    final value = _data[field];
    if (value is String && value.trim().length > max) {
      _addError(
        field,
        message ?? 'The $field field must not exceed $max characters.',
      );
    }
    return this;
  }

  Validator notEmpty(String field, {String? message}) {
    final value = _data[field];
    if (value is String && value.trim().isEmpty) {
      _addError(field, message ?? 'The $field field must not be empty.');
    }
    return this;
  }

  // ── Result ─────────────────────────────────────────────────────────────────

  bool get isValid => _errors.isEmpty;

  Map<String, List<String>> get errors => Map.unmodifiable(_errors);

  /// Throws [ValidationException] if any rule failed.
  void validate() {
    if (_errors.isNotEmpty) throw ValidationException(Map.of(_errors));
  }

  // ── private ────────────────────────────────────────────────────────────────

  void _addError(String field, String message) {
    _errors.putIfAbsent(field, () => []).add(message);
  }
}
