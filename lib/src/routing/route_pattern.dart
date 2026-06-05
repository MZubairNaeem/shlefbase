/// Compiles a ShelfBase route pattern into a [RegExp] and extracts named
/// URL parameters on every match.
///
/// Pattern syntax:
///   `/users`          — literal path segment
///   `/users/<id>`     — named segment, captured as `params['id']`
///   `/files/<path:*>` — greedy segment (matches slashes too)
///
/// Examples:
/// ```dart
/// final p = RoutePattern('/users/<id>');
/// p.match('/users/42');      // → {'id': '42'}
/// p.match('/users');         // → null
/// p.match('/users/42/edit'); // → null
/// ```
class RoutePattern {
  final String _original;
  final RegExp _regex;
  final List<String> _names;

  RoutePattern._(this._original, this._regex, this._names);

  factory RoutePattern(String pattern) {
    final names = <String>[];
    final regex = _compile(pattern, names);
    return RoutePattern._(pattern, regex, names);
  }

  // ── public API ────────────────────────────────────────────────────────────

  /// Returns extracted parameters if [path] matches this pattern, else `null`.
  Map<String, String>? match(String path) {
    final m = _regex.firstMatch(path);
    if (m == null) return null;
    return {for (final name in _names) name: m.namedGroup(name)!};
  }

  /// Whether [path] matches this pattern.
  bool matches(String path) => _regex.hasMatch(path);

  /// Generates a concrete URL by substituting [params] into the pattern.
  ///
  /// ```dart
  /// RoutePattern('/users/<id>').url({'id': '42'}); // → '/users/42'
  /// ```
  String url(Map<String, String> params) {
    return _original.replaceAllMapped(
      RegExp(r'<(\w+)(?::[^>]+)?>'),
      (m) => params[m[1]] ?? m[0]!,
    );
  }

  @override
  String toString() => _original;

  // ── private ───────────────────────────────────────────────────────────────

  static RegExp _compile(String pattern, List<String> names) {
    // We mutate [names] in place so the constructor can read it after.
    final buf = StringBuffer('^');
    final segments = pattern.split('/');

    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (i > 0) buf.write(r'\/');

      final paramMatch = RegExp(r'^<(\w+)(?::(\*))?>$').firstMatch(seg);
      if (paramMatch != null) {
        final name = paramMatch[1]!;
        final greedy = paramMatch[2] == '*';
        names.add(name);
        // Greedy → matches slashes too; default → any non-slash sequence.
        buf.write(greedy ? '(?<$name>.+)' : '(?<$name>[^/]+)');
      } else {
        buf.write(RegExp.escape(seg));
      }
    }

    buf.write(r'$');
    return RegExp(buf.toString());
  }
}
