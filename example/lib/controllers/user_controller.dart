import 'package:shelfbase/shelfbase.dart';

import '../services/user_service.dart';

/// Plain class — no base class required.
///
/// Extends [ResourceController] only because we use [Router.resource].
/// For manually registered routes, any class (or top-level functions) works.
class UserController extends ResourceController {
  final UserService _service;

  UserController(this._service);

  // ── index: GET /users ─────────────────────────────────────────────────────

  @override
  Response index(Request request) {
    final page = int.tryParse(request.query('page') ?? '1') ?? 1;
    final users = _service.findAll(page: page);
    return Response.json({
      'data': users,
      'page': page,
      'total': users.length,
    });
  }

  // ── show: GET /users/<id> ─────────────────────────────────────────────────

  @override
  Response show(Request request) {
    final id = request.param('id');
    final user = _service.findOne(id);
    if (user == null) return Response.notFound('User $id not found');
    return Response.json(user);
  }

  // ── store: POST /users ────────────────────────────────────────────────────

  @override
  Future<Response> store(Request request) async {
    final Map<String, dynamic> body;
    try {
      body = await request.jsonMap();
    } on FormatException {
      return Response.badRequest('Request body must be valid JSON');
    }

    final name = body['name'] as String?;
    final email = body['email'] as String?;

    if (name == null || email == null) {
      return Response.unprocessable({
        'name': name == null ? ['required'] : [],
        'email': email == null ? ['required'] : [],
      });
    }

    final user = _service.create(name, email);
    return Response.created(user);
  }

  // ── update: PUT /users/<id> ───────────────────────────────────────────────

  @override
  Future<Response> update(Request request) async {
    final id = request.param('id');
    final body = await request.jsonMap();
    final user = _service.update(id, body);
    if (user == null) return Response.notFound('User $id not found');
    return Response.json(user);
  }

  // ── destroy: DELETE /users/<id> ───────────────────────────────────────────

  @override
  Response destroy(Request request) {
    final id = request.param('id');
    final removed = _service.delete(id);
    if (!removed) return Response.notFound('User $id not found');
    return Response.noContent();
  }
}
