class ValidationException implements Exception {
  final Map<String, List<String>> errors;

  const ValidationException(this.errors);

  @override
  String toString() => 'ValidationException: $errors';
}
