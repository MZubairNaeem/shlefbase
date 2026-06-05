import '../generator_context.dart';
import 'controller_generator.dart';
import 'generator_base.dart';
import 'module_generator.dart';
import 'routes_generator.dart';
import 'service_generator.dart';

/// Generates the full triad — service + controller + module — in one shot.
///
/// This is the `shelfbase generate resource <name>` command and the fastest
/// way to scaffold a new feature slice.
abstract final class ResourceGenerator {
  static Future<void> generate(
    GeneratorContext ctx, {
    bool dryRun = false,
    bool force = false,
  }) async {
    GeneratorBase.printHeading(
      'Generating ${ctx.className} resource in ${ctx.outputDir}',
    );

    await ServiceGenerator.generate(ctx, dryRun: dryRun, force: force);
    await ControllerGenerator.generate(
      ctx,
      dryRun: dryRun,
      force: force,
      withService: true,
    );
    await ModuleGenerator.generate(
      ctx,
      dryRun: dryRun,
      force: force,
      withResource: true,
    );
    await RoutesGenerator.generate(ctx, dryRun: dryRun, force: force);

    GeneratorBase.printDone();
  }
}
