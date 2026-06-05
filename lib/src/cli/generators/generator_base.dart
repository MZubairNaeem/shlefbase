import 'dart:convert';
import 'dart:io';

/// Shared file-writing utilities used by every generator.
abstract final class GeneratorBase {
  /// Writes [content] to [path], printing a coloured status line.
  ///
  /// Behaviour:
  ///  - [dryRun]  — prints what would happen without touching the filesystem.
  ///  - [force]   — overwrites an existing file; otherwise the file is skipped.
  static Future<bool> writeFile(
    String path,
    String content, {
    bool dryRun = false,
    bool force = false,
  }) async {
    final file = File(path);
    final relPath = _relativeToCwd(path);

    if (file.existsSync() && !force && !dryRun) {
      _print(_yellow('SKIP  '), '$relPath (already exists — use --force to overwrite)');
      return false;
    }

    final bytes = utf8.encode(content).length;

    if (dryRun) {
      _print(_cyan('DRY   '), '$relPath ($bytes bytes)');
      return true;
    }

    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    _print(_green('CREATE'), '$relPath ($bytes bytes)');
    return true;
  }

  /// Prints a section header (e.g. "Generating Users resource").
  static void printHeading(String message) =>
      print('\n\x1B[1m$message\x1B[0m');

  /// Prints a success summary.
  static void printDone() => print('');

  // ── ANSI helpers ─────────────────────────────────────────────────────────

  static String _green(String s) => '\x1B[32m$s\x1B[0m';
  static String _yellow(String s) => '\x1B[33m$s\x1B[0m';
  static String _cyan(String s) => '\x1B[36m$s\x1B[0m';

  static void _print(String label, String message) =>
      print('  $label  $message');

  static String _relativeToCwd(String absolute) {
    final cwd = Directory.current.path;
    return absolute.startsWith(cwd)
        ? absolute.substring(cwd.length + 1)
        : absolute;
  }
}
