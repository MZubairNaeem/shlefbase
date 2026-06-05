import 'dart:io';

import 'package:args/command_runner.dart';

import '../generator_context.dart';
import '../generators/controller_generator.dart';
import '../generators/middleware_generator.dart';
import '../generators/module_generator.dart';
import '../generators/provider_generator.dart';
import '../generators/resource_generator.dart';
import '../generators/service_generator.dart';

// ── Shared option mixin ────────────────────────────────────────────────────

mixin _MakeOptions on Command<int> {
  bool get _dryRun => argResults!['dry-run'] as bool;
  bool get _force => argResults!['force'] as bool;
  bool get _flat => argResults!['flat'] as bool;
  String get _outputPath => argResults!['path'] as String;

  void _addCommonOptions() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Output directory relative to lib/ (e.g. Http/Controllers).',
        defaultsTo: '',
      )
      ..addFlag(
        'flat',
        negatable: false,
        help: 'Write directly to lib/<path> without a per-name subdirectory.',
      )
      ..addFlag(
        'dry-run',
        abbr: 'd',
        negatable: false,
        help: 'Preview output paths without writing files.',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        negatable: false,
        help: 'Overwrite existing files.',
      );
  }

  String _requireName() {
    final rest = argResults!.rest;
    if (rest.isEmpty) usageException('Missing required argument: <name>');
    return rest.first;
  }

  GeneratorContext _ctx(String rawName, {String? stripSuffix}) {
    var name = rawName;
    if (stripSuffix != null) name = _strip(name, stripSuffix);

    // Apply --path by prepending it to the name so GeneratorContext resolves
    // the correct output directory.
    final path = _outputPath.trim();
    final qualified = path.isEmpty ? name : '$path/$name';

    return GeneratorContext.parse(qualified, flat: _flat);
  }

  /// Removes a PascalCase [suffix] from [name] if present.
  static String _strip(String name, String suffix) {
    if (name.endsWith(suffix)) return name.substring(0, name.length - suffix.length);
    return name;
  }
}

// ── make:controller ────────────────────────────────────────────────────────

/// `dart run shelfbase make:controller <Name>`
class MakeControllerCommand extends Command<int> with _MakeOptions {
  @override
  String get name => 'make:controller';

  @override
  String get description =>
      'Generate a new controller class with CRUD route handlers.';

  @override
  String get invocation =>
      '${runner!.executableName} make:controller <Name> [options]';

  @override
  String get usage => '''
Generate a new controller class.

Usage: ${runner!.executableName} make:controller <Name> [options]

The <Name> should be the feature name without the "Controller" suffix.
The suffix is added automatically.

  make:controller User          → lib/user/user.controller.dart (UserController)
  make:controller Api/User      → lib/api/user/user.controller.dart
  make:controller User --flat   → lib/user.controller.dart

${argParser.usage}''';

  MakeControllerCommand() {
    _addCommonOptions();
    argParser.addFlag(
      'no-service',
      negatable: false,
      help: 'Generate a standalone controller without a service dependency.',
    );
  }

  @override
  Future<int> run() async {
    _checkRoot();
    final ctx = _ctx(_requireName(), stripSuffix: 'Controller');
    final noService = argResults!['no-service'] as bool;
    await ControllerGenerator.generate(
      ctx,
      dryRun: _dryRun,
      force: _force,
      withService: !noService,
    );
    return 0;
  }
}

// ── make:service ───────────────────────────────────────────────────────────

/// `dart run shelfbase make:service <Name>`
class MakeServiceCommand extends Command<int> with _MakeOptions {
  @override
  String get name => 'make:service';

  @override
  String get description => 'Generate a new service class.';

  @override
  String get invocation =>
      '${runner!.executableName} make:service <Name> [options]';

  MakeServiceCommand() {
    _addCommonOptions();
  }

  @override
  Future<int> run() async {
    _checkRoot();
    await ServiceGenerator.generate(
      _ctx(_requireName(), stripSuffix: 'Service'),
      dryRun: _dryRun,
      force: _force,
    );
    return 0;
  }
}

// ── make:module ────────────────────────────────────────────────────────────

/// `dart run shelfbase make:module <Name>`
class MakeModuleCommand extends Command<int> with _MakeOptions {
  @override
  String get name => 'make:module';

  @override
  String get description =>
      'Generate a module registration function (registerXModule).';

  @override
  String get invocation =>
      '${runner!.executableName} make:module <Name> [options]';

  MakeModuleCommand() {
    _addCommonOptions();
  }

  @override
  Future<int> run() async {
    _checkRoot();
    await ModuleGenerator.generate(
      _ctx(_requireName(), stripSuffix: 'Module'),
      dryRun: _dryRun,
      force: _force,
    );
    return 0;
  }
}

// ── make:middleware ────────────────────────────────────────────────────────

/// `dart run shelfbase make:middleware <Name>`
class MakeMiddlewareCommand extends Command<int> with _MakeOptions {
  @override
  String get name => 'make:middleware';

  @override
  String get description => 'Generate a new Middleware class.';

  @override
  String get invocation =>
      '${runner!.executableName} make:middleware <Name> [options]';

  MakeMiddlewareCommand() {
    _addCommonOptions();
  }

  @override
  Future<int> run() async {
    _checkRoot();
    await MiddlewareGenerator.generate(
      _ctx(_requireName(), stripSuffix: 'Middleware'),
      dryRun: _dryRun,
      force: _force,
    );
    return 0;
  }
}

// ── make:provider ──────────────────────────────────────────────────────────

/// `dart run shelfbase make:provider <Name>`
class MakeProviderCommand extends Command<int> with _MakeOptions {
  @override
  String get name => 'make:provider';

  @override
  String get description => 'Generate a new ServiceProvider class.';

  @override
  String get invocation =>
      '${runner!.executableName} make:provider <Name> [options]';

  MakeProviderCommand() {
    _addCommonOptions();
  }

  @override
  Future<int> run() async {
    _checkRoot();
    await ProviderGenerator.generate(
      _ctx(_requireName(), stripSuffix: 'ServiceProvider'),
      dryRun: _dryRun,
      force: _force,
    );
    return 0;
  }
}

// ── make:resource ──────────────────────────────────────────────────────────

/// `dart run shelfbase make:resource <Name>`
///
/// Generates service + controller + module in one command.
class MakeResourceCommand extends Command<int> with _MakeOptions {
  @override
  String get name => 'make:resource';

  @override
  String get description =>
      'Generate a full resource slice: service + controller + module.';

  @override
  String get invocation =>
      '${runner!.executableName} make:resource <Name> [options]';

  MakeResourceCommand() {
    _addCommonOptions();
  }

  @override
  Future<int> run() async {
    _checkRoot();
    await ResourceGenerator.generate(
      _ctx(_requireName()),
      dryRun: _dryRun,
      force: _force,
    );
    return 0;
  }
}

// ── shared guard ───────────────────────────────────────────────────────────

void _checkRoot() {
  if (!File('pubspec.yaml').existsSync()) {
    stderr.writeln(
      '\x1B[33m[warn]\x1B[0m No pubspec.yaml found. '
      'Run shelfbase commands from your project root.',
    );
  }
}
