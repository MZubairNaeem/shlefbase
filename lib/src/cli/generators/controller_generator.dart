import '../generator_context.dart';
import 'generator_base.dart';

abstract final class ControllerGenerator {
  static Future<bool> generate(
    GeneratorContext ctx, {
    bool dryRun = false,
    bool force = false,

    /// When true the service field and service-specific body are included.
    bool withService = true,
  }) {
    return GeneratorBase.writeFile(
      ctx.filePath('controller'),
      _template(ctx, withService: withService),
      dryRun: dryRun,
      force: force,
    );
  }

  static String _template(GeneratorContext ctx, {required bool withService}) {
    final svcImport = withService
        ? "\nimport '${ctx.snakeName}.service.dart';"
        : '';
    final svcField = withService
        ? '''
  final ${ctx.className}Service _service;
  ${ctx.className}Controller(this._service);
'''
        : '  ${ctx.className}Controller();';

    final svcBody = withService ? '_service' : null;

    return '''
import 'dart:convert';

import 'package:shelfbase/shelfbase.dart';$svcImport

class ${ctx.className}Controller extends ResourceController {
$svcField
  // GET  ${ctx.routePath}
  @override
  Response index(Request request) {
    final page = int.tryParse(request.query('page') ?? '1') ?? 1;
    ${svcBody != null ? "return Response.json({'data': $svcBody.findAll(), 'page': page});" : '// TODO: implement index\n    return Response.json({\'data\': []});'}
  }

  // GET  ${ctx.routePath}/<id>
  @override
  Response show(Request request) {
    final id = request.param('id');
    ${svcBody != null ? '''final item = $svcBody.findOne(id);
    return item != null ? Response.json(item) : Response.notFound('\$id not found');''' : '// TODO: implement show\n    return Response.json({\'id\': request.param(\'id\')});'}
  }

  // POST ${ctx.routePath}
  @override
  Future<Response> store(Request request) async {
    final body = await request.jsonMap();
    ${svcBody != null ? "return Response.created($svcBody.create(body));" : '// TODO: implement store\n    return Response.created(body);'}
  }

  // PUT  ${ctx.routePath}/<id>
  @override
  Future<Response> update(Request request) async {
    final id = request.param('id');
    final body = await request.jsonMap();
    ${svcBody != null ? '''final item = $svcBody.update(id, body);
    return item != null ? Response.json(item) : Response.notFound('\$id not found');''' : '// TODO: implement update\n    return Response.json(body);'}
  }

  // DELETE ${ctx.routePath}/<id>
  @override
  Response destroy(Request request) {
    final id = request.param('id');
    ${svcBody != null ? "$svcBody.remove(id);\n    return Response.noContent();" : '// TODO: implement destroy\n    return Response.noContent();'}
  }
}
''';
  }
}
