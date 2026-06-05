import 'package:args/command_runner.dart';

import '../generators/init_generator.dart';

/// `dart run shelfbase init`
///
/// Run once after adding shelfbase to pubspec.yaml and `dart pub get`:
///
/// ```
/// dependencies:
///   shelfbase:
///     git:
///       url: https://github.com/MZubairNaeem/shlefbase.git
///       ref: main
/// ```
///
/// ```
/// dart pub get
/// dart run shelfbase init      # scaffold the project
/// dart run shelfbase serve     # start the server
/// ```
class InitCommand extends Command<int> {
  @override
  String get name => 'init';

  @override
  String get description =>
      'Scaffold a new ShelfBase project structure (run once after dart pub get).';

  @override
  String get invocation => '${runner!.executableName} init [options]';

  @override
  String get usage => '''
Scaffold bin/main.dart, lib/routes/, lib/controllers/, lib/middleware/, and lib/providers/.

Usage: ${runner!.executableName} init [options]

${argParser.usage}''';

  InitCommand() {
    argParser
      ..addFlag(
        'dry-run',
        abbr: 'd',
        negatable: false,
        help: 'Preview which files would be created without writing anything.',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Overwrite existing files.',
      );
  }

  @override
  Future<int> run() async {
    final dryRun = argResults!['dry-run'] as bool;
    final force = argResults!['force'] as bool;

    await InitGenerator.generate(dryRun: dryRun, force: force);
    return 0;
  }
}
