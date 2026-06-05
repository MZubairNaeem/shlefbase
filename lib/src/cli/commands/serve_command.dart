import 'dart:io';

import 'package:args/command_runner.dart';

/// `dart run shelfbase serve`
///
/// Discovers and launches the project's entry point via `dart run`,
/// inheriting stdio so all server output (including ANSI colours) flows
/// directly to the terminal.
///
/// Entry-point resolution order:
///   1. `--entry` flag (explicit override)
///   2. `bin/main.dart`
///   3. `bin/<pubspec-name>.dart`
///   4. First `*.dart` file found in `bin/`
class ServeCommand extends Command<int> {
  @override
  String get name => 'serve';

  @override
  String get description => 'Start the ShelfBase application server.';

  @override
  String get invocation => '${runner!.executableName} serve [options]';

  @override
  String get usage => '''
Discover and run the project's entry point.

Usage: ${runner!.executableName} serve [options]

${argParser.usage}''';

  ServeCommand() {
    argParser
      ..addOption(
        'entry',
        abbr: 'e',
        help: 'Entry-point file to run (relative to project root).',
        valueHelp: 'bin/main.dart',
      )
      ..addOption(
        'port',
        abbr: 'p',
        help: 'Port to listen on. Exposed to the app as the PORT env var.',
        valueHelp: '8080',
      )
      ..addOption(
        'host',
        help: 'Host to bind to. Exposed to the app as the HOST env var.',
        valueHelp: 'localhost',
      );
  }

  @override
  Future<int> run() async {
    _checkRoot();

    final entryArg = argResults!['entry'] as String?;
    final portArg = argResults!['port'] as String?;
    final hostArg = argResults!['host'] as String?;

    final entry = entryArg ?? _discoverEntry();
    if (entry == null) {
      stderr.writeln(
        '\x1B[31merror:\x1B[0m No entry point found.\n'
        '  Create \x1B[33mbin/main.dart\x1B[0m or pass \x1B[33m--entry <file>\x1B[0m.',
      );
      return 1;
    }

    // Build env — inherit everything, then overlay PORT/HOST overrides.
    final env = Map<String, String>.from(Platform.environment);
    if (portArg != null) env['PORT'] = portArg;
    if (hostArg != null) env['HOST'] = hostArg;

    _printStartBanner(entry, portArg, hostArg);

    final process = await Process.start(
      Platform.resolvedExecutable, // the `dart` SDK binary
      ['run', entry, ...argResults!.rest],
      environment: env,
      // Inherit stdio — child output goes directly to the terminal,
      // preserving ANSI colours and interactive behaviour.
      mode: ProcessStartMode.inheritStdio,
    );

    // When the user presses Ctrl+C the terminal sends SIGINT to the
    // whole process group, so the child already gets it. We listen here
    // only to avoid the parent exiting before the child has cleaned up.
    ProcessSignal.sigint.watch().listen((_) {
      process.kill(ProcessSignal.sigint);
    });

    return process.exitCode;
  }

  // ── Entry-point discovery ─────────────────────────────────────────────────

  String? _discoverEntry() {
    // 1. Conventional name.
    if (File('bin/main.dart').existsSync()) return 'bin/main.dart';

    // 2. pubspec `name:` field  →  bin/<name>.dart
    final pubspec = File('pubspec.yaml');
    if (pubspec.existsSync()) {
      final content = pubspec.readAsStringSync();
      final match =
          RegExp(r'^name:\s+(\S+)', multiLine: true).firstMatch(content);
      if (match != null) {
        final candidate = 'bin/${match.group(1)!}.dart';
        if (File(candidate).existsSync()) return candidate;
      }
    }

    // 3. Any .dart file in bin/.
    final binDir = Directory('bin');
    if (binDir.existsSync()) {
      final files = binDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      if (files.isNotEmpty) return files.first.path;
    }

    return null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _checkRoot() {
    if (!File('pubspec.yaml').existsSync()) {
      stderr.writeln(
        '\x1B[33m[warn]\x1B[0m No pubspec.yaml found. '
        'Run this command from your project root.',
      );
    }
  }

  void _printStartBanner(String entry, String? port, String? host) {
    final portLabel = port != null ? '  port  → \x1B[36m$port\x1B[0m' : '';
    final hostLabel = host != null ? '  host  → \x1B[36m$host\x1B[0m' : '';
    final extras =
        [portLabel, hostLabel].where((s) => s.isNotEmpty).join('\n');

    stdout.writeln('\x1B[32m[ShelfBase]\x1B[0m serve  → \x1B[36m$entry\x1B[0m'
        '${extras.isNotEmpty ? '\n$extras' : ''}');
  }
}
