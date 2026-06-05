import '../generator_context.dart';
import 'generator_base.dart';

abstract final class ProviderGenerator {
  static Future<bool> generate(
    GeneratorContext ctx, {
    bool dryRun = false,
    bool force = false,
  }) {
    return GeneratorBase.writeFile(
      ctx.filePath('provider'),
      _template(ctx),
      dryRun: dryRun,
      force: force,
    );
  }

  static String _template(GeneratorContext ctx) => '''
import 'package:shelfbase/shelfbase.dart';

class ${ctx.className}ServiceProvider extends ServiceProvider {
  /// Bind services into the IoC container.
  ///
  /// Called before [boot] — do not call [app.make] here.
  @override
  void register() {
    // app.singleton<${ctx.className}Service>((_) => ${ctx.className}Service());
  }

  /// Run code that depends on other providers already being registered.
  @override
  Future<void> boot() async {
    // await app.make<${ctx.className}Service>().init();
  }
}
''';
}
