import 'dart:io';

import '../generator_context.dart';
import 'generator_base.dart';

/// Manages `lib/routes/api.dart` — the central Laravel-style routes file.
///
/// On first resource generation the file is created with a full scaffold.
/// When the file already exists, a hint block is printed so the developer
/// can paste the new routes in by hand (safe: avoids clobbering custom edits).
abstract final class RoutesGenerator {
  static Future<void> generate(
    GeneratorContext ctx, {
    bool dryRun = false,
    bool force = false,
  }) async {
    final cwd = Directory.current.path;
    final routesPath = '$cwd/lib/routes/api.dart';
    final exists = File(routesPath).existsSync();

    if (exists && !force) {
      _printHint(ctx);
      return;
    }

    await GeneratorBase.writeFile(
      routesPath,
      _scaffold(ctx),
      dryRun: dryRun,
      force: force,
    );
  }

  // ── templates ─────────────────────────────────────────────────────────────

  static String _scaffold(GeneratorContext ctx) {
    final rel = _relativeImport(ctx);
    return '''
import 'package:shelfbase/shelfbase.dart';

$rel

/// Register all API routes here.
///
/// Laravel-style dispatch: use<ControllerType>((c) => c.method)
/// resolves the controller from the IoC container and delegates to the method.
///
/// Add this function to your entry point:
///   registerApiRoutes(application.router);
void registerApiRoutes(Router r) {
  r.group(
    prefix: '/api',
    routes: (r) {
${_routeBlock(ctx)}    },
  );
}
''';
  }

  static String _routeBlock(GeneratorContext ctx) {
    final p = ctx.routePath;
    final c = '${ctx.className}Controller';
    return '''
      // ${ctx.className} — ${ctx.routePath}
      r.get('$p',         use<$c>((c) => c.index));
      r.post('$p',        use<$c>((c) => c.store));
      r.get('$p/<id>',    use<$c>((c) => c.show));
      r.put('$p/<id>',    use<$c>((c) => c.update));
      r.patch('$p/<id>',  use<$c>((c) => c.update));
      r.delete('$p/<id>', use<$c>((c) => c.destroy));
''';
  }

  static String _relativeImport(GeneratorContext ctx) {
    final cwd = Directory.current.path;
    final libBase = '$cwd/lib';
    final absolute = ctx.filePath('controller');
    final relative = absolute.startsWith(libBase)
        ? absolute.substring(libBase.length + 1)
        : absolute;
    return "import '../$relative';";
  }

  // ── hint (when api.dart already exists) ───────────────────────────────────

  static void _printHint(GeneratorContext ctx) {
    final c = '${ctx.className}Controller';
    final p = ctx.routePath;
    stdout.writeln(
      '\n  \x1B[36mHINT\x1B[0m  '
      'lib/routes/api.dart already exists.\n'
      '        Add these routes inside registerApiRoutes():\n',
    );
    stdout.writeln(
      "        // ${ctx.className} — $p\n"
      "        r.get('$p',         use<$c>((c) => c.index));\n"
      "        r.post('$p',        use<$c>((c) => c.store));\n"
      "        r.get('$p/<id>',    use<$c>((c) => c.show));\n"
      "        r.put('$p/<id>',    use<$c>((c) => c.update));\n"
      "        r.patch('$p/<id>',  use<$c>((c) => c.update));\n"
      "        r.delete('$p/<id>', use<$c>((c) => c.destroy));\n",
    );
  }
}
