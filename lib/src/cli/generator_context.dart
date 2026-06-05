import 'dart:io';

/// Parses a raw user-supplied name into every identifier variant the
/// generators need.
///
/// Accepted input forms:
///   `users`           → simple name
///   `auth/users`      → name inside a subdirectory
///   `UserProfile`     → PascalCase input
///   `user-profile`    → kebab-case input
///   `user_profile`    → snake_case input
///
/// All variants are normalised to snake_case internally.
class GeneratorContext {
  /// snake_case stem — used as the file name prefix (e.g. `user_profile`)
  final String snakeName;

  /// PascalCase class name (e.g. `UserProfile`)
  final String className;

  /// HTTP route path in kebab-case (e.g. `/user-profile`)
  final String routePath;

  /// Absolute path to the output directory.
  ///
  /// Defaults to `<cwd>/lib/<snakeName>` or
  /// `<cwd>/lib/<subdir>/<snakeName>`.
  /// With [flat], no extra subdirectory is created.
  final String outputDir;

  const GeneratorContext._({
    required this.snakeName,
    required this.className,
    required this.routePath,
    required this.outputDir,
  });

  /// Resolves a file path inside [outputDir].
  String filePath(String suffix) => '$outputDir/$snakeName.$suffix.dart';

  // ── factory ──────────────────────────────────────────────────────────────

  /// Parses [input] (e.g. `'users'` or `'auth/users'`) into a context.
  ///
  /// [flat] — when true, files land in `lib/<subdir>` instead of
  ///          `lib/<subdir>/<snakeName>`.
  factory GeneratorContext.parse(String input, {bool flat = false}) {
    final segments = input.trim().split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }

    final rawName = segments.last;
    final subPath = segments.length > 1
        ? segments.sublist(0, segments.length - 1).join('/')
        : null;

    final snake = _toSnakeCase(rawName);
    final pascal = _toPascalCase(snake);
    final route = '/${snake.replaceAll('_', '-')}';

    final cwd = Directory.current.path;
    final libBase = '$cwd/lib';
    final String dir;

    if (flat) {
      dir = subPath != null ? '$libBase/$subPath' : libBase;
    } else {
      dir = subPath != null ? '$libBase/$subPath/$snake' : '$libBase/$snake';
    }

    return GeneratorContext._(
      snakeName: snake,
      className: pascal,
      routePath: route,
      outputDir: dir,
    );
  }

  // ── name helpers ─────────────────────────────────────────────────────────

  /// Converts any common casing to `snake_case`.
  static String _toSnakeCase(String input) {
    var s = input
        // camelCase → camel_Case
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]}_${m[2]}',
        )
        // PascalCase leading cap
        .replaceAllMapped(
          RegExp(r'([A-Z]+)([A-Z][a-z])'),
          (m) => '${m[1]}_${m[2]}',
        );
    // Replace hyphens / spaces with underscores, then lowercase everything.
    return s.replaceAll(RegExp(r'[-\s]+'), '_').toLowerCase();
  }

  /// Converts `snake_case` to `PascalCase`.
  static String _toPascalCase(String snake) {
    return snake
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join();
  }
}
