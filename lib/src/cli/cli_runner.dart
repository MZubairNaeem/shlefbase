import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/init_command.dart';
import 'commands/make_commands.dart';
import 'commands/serve_command.dart';

/// Entry point for the ShelfBase CLI.
///
/// Invoked via:
/// ```
/// dart run shelfbase <command> [options]
/// ```
class CliRunner {
  final CommandRunner<int> _runner;

  CliRunner()
      : _runner = CommandRunner<int>(
          'shelfbase',
          'ShelfBase — Laravel-inspired Dart backend framework',
        ) {
    _runner
      ..addCommand(InitCommand())
      ..addCommand(ServeCommand())
      ..addCommand(MakeControllerCommand())
      ..addCommand(MakeServiceCommand())
      ..addCommand(MakeModuleCommand())
      ..addCommand(MakeMiddlewareCommand())
      ..addCommand(MakeProviderCommand())
      ..addCommand(MakeResourceCommand());

    _runner.argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the ShelfBase CLI version.',
    );
  }

  Future<int> run(List<String> args) async {
    try {
      if (args.isEmpty) {
        _printBanner();
        _runner.printUsage();
        return 0;
      }

      if (args.contains('--version') || args.contains('-v')) {
        stdout.writeln('ShelfBase v0.1.0');
        return 0;
      }

      final result = await _runner.run(args);
      return result ?? 0;
    } on UsageException catch (e) {
      stderr.writeln('\x1B[31merror:\x1B[0m ${e.message}\n');
      stderr.writeln(e.usage);
      return 64;
    } catch (e) {
      stderr.writeln('\x1B[31merror:\x1B[0m $e');
      return 1;
    }
  }

  void _printBanner() {
    stdout.writeln('''
  ____  _          _  __ ____
 / ___|| |__   ___| |/ _| __ )  __ _ ___  ___
 \\___ \\| '_ \\ / _ \\ | |_|  _ \\ / _` / __|/ _ \\
  ___) | | | |  __/ |  _| |_) | (_| \\__ \\  __/
 |____/|_| |_|\\___|_|_| |____/ \\__,_|___/\\___|

 Laravel-inspired Dart backend framework  v0.1.0
''');
  }
}
