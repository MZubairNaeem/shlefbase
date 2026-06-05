import 'dart:convert';

import 'package:shelfbase/shelfbase.dart';

import 'user.service.dart';

/// Handles all HTTP requests under `/users`.
///
/// Demonstrates:
///   - Injecting a service via constructor (DI)
///   - Declaring routes explicitly with [RouteEntry]
///   - Using [Res] for clean JSON responses
///   - Accessing URL path params via [Request.params]
///   - Reading the request body for POST
@Controller('/users')
class UserController extends ShelfBaseController {
  final UserService _service;

  UserController(this._service);

  // ── ShelfBaseController contract ─────────────────────────────────────────

  @override
  String get prefix => '/users';

  @override
  List<RouteEntry> get routes => [
        RouteEntry.get('/', _getAll),
        RouteEntry.get('/<id>', _getOne),
        RouteEntry.post('/', _create),
        RouteEntry.delete('/<id>', _delete),
      ];

  // ── Handlers ─────────────────────────────────────────────────────────────

  @Get('/')
  Response _getAll(Request req) {
    return Res.ok(_service.findAll());
  }

  /// Path param is passed as a positional arg by shelf_router.
  @Get('/<id>')
  Response _getOne(Request req, String id) {
    final user = _service.findOne(id);
    if (user == null) return Res.notFound('User $id not found');
    return Res.ok(user);
  }

  @Post('/')
  Future<Response> _create(Request req) async {
    final body = await req.readAsString();
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } on FormatException {
      return Res.badRequest('Request body must be valid JSON');
    }

    final name = data['name'] as String?;
    final email = data['email'] as String?;
    if (name == null || email == null) {
      return Res.badRequest('Fields "name" and "email" are required');
    }

    final created = _service.create(name, email);
    return Res.created(created);
  }

  @Delete('/<id>')
  Response _delete(Request req, String id) {
    final removed = _service.delete(id);
    if (!removed) return Res.notFound('User $id not found');
    return Res.noContent();
  }
}
