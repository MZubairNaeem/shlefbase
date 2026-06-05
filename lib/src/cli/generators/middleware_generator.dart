import '../generator_context.dart';
import 'generator_base.dart';

abstract final class MiddlewareGenerator {
  static Future<bool> generate(
    GeneratorContext ctx, {
    bool dryRun = false,
    bool force = false,
  }) {
    return GeneratorBase.writeFile(
      ctx.filePath('middleware'),
      _template(ctx),
      dryRun: dryRun,
      force: force,
    );
  }

  static String _template(GeneratorContext ctx) => '''
import 'package:shelfbase/shelfbase.dart';

class ${ctx.className}Middleware implements Middleware {
  @override
  Future<Response> handle(Request request, Next next) async {
    // TODO: implement ${ctx.className}Middleware logic

    // Example: inspect / modify request before the handler
    // if (request.header('x-api-key') == null) {
    //   return Response.unauthorized('Missing API key');
    // }

    final response = await next(request);

    // Example: modify response before returning
    return response.withHeader('X-Handled-By', '${ctx.className}Middleware');
  }
}
''';
}
