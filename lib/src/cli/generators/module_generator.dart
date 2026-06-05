import '../generator_context.dart';
import 'generator_base.dart';

abstract final class ModuleGenerator {
  static Future<bool> generate(
    GeneratorContext ctx, {
    bool dryRun = false,
    bool force = false,
    bool withResource = false,
  }) {
    return GeneratorBase.writeFile(
      ctx.filePath('module'),
      withResource ? _resourceTemplate(ctx) : _bareTemplate(ctx),
      dryRun: dryRun,
      force: force,
    );
  }

  /// A bare module registration snippet (add to Application in main.dart).
  static String _bareTemplate(GeneratorContext ctx) => '''
import 'package:shelfbase/shelfbase.dart';

/// Registers ${ctx.className} services and routes.
///
/// Call inside main.dart:
/// ```dart
/// register${ctx.className}Module(app);
/// ```
void register${ctx.className}Module(Application app) {
  // Register services
  // app.singleton<${ctx.className}Service>((_) => ${ctx.className}Service());

  // Register routes
  // app.router.get('${ctx.routePath}', (req) => Response.json({}));
}
''';

  /// A full module that wires service + resource controller onto a router group.
  static String _resourceTemplate(GeneratorContext ctx) => '''
import 'package:shelfbase/shelfbase.dart';

import '${ctx.snakeName}.controller.dart';
import '${ctx.snakeName}.service.dart';

/// Registers ${ctx.className} services and resource routes.
///
/// Call inside main.dart:
/// ```dart
/// register${ctx.className}Module(app);
/// ```
void register${ctx.className}Module(Application app) {
  app.singleton<${ctx.className}Service>((_) => ${ctx.className}Service());

  app.router.resource(
    '${ctx.routePath}',
    ${ctx.className}Controller(app.make<${ctx.className}Service>()),
  );
}
''';
}
