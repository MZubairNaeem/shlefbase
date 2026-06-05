import 'package:shelfbase/shelfbase.dart';
import 'package:test/test.dart';

Response _noop(Request req) => Response.json({});

class _FakeResource extends ResourceController {
  @override
  Response index(Request req) => Response.json({});
  @override
  Response show(Request req) => Response.json({});
  @override
  Response store(Request req) => Response.json({});
  @override
  Response update(Request req) => Response.json({});
  @override
  Response destroy(Request req) => Response.json({});
}

void main() {
  late Router router;
  setUp(() => router = Router());

  group('Router — basic verb methods', () {
    test('get registers a GET route', () {
      router.get('/test', _noop);
      expect(router.routes.first.method, 'GET');
      expect(router.routes.first.path, '/test');
    });

    test('post registers a POST route', () {
      router.post('/test', _noop);
      expect(router.routes.first.method, 'POST');
    });

    test('put registers a PUT route', () {
      router.put('/test', _noop);
      expect(router.routes.first.method, 'PUT');
    });

    test('patch registers a PATCH route', () {
      router.patch('/test', _noop);
      expect(router.routes.first.method, 'PATCH');
    });

    test('delete registers a DELETE route', () {
      router.delete('/test', _noop);
      expect(router.routes.first.method, 'DELETE');
    });

    test('any registers an ANY route', () {
      router.any('/test', _noop);
      expect(router.routes.first.method, 'ANY');
    });
  });

  group('Router — resource', () {
    test('resource registers 6 routes', () {
      router.resource('/users', _FakeResource());
      expect(router.routes, hasLength(6));
    });

    test('resource paths are correct', () {
      router.resource('/users', _FakeResource());
      final paths = router.routes.map((r) => '${r.method} ${r.path}').toSet();
      expect(paths, containsAll([
        'GET /users',
        'GET /users/<id>',
        'POST /users',
        'PUT /users/<id>',
        'PATCH /users/<id>',
        'DELETE /users/<id>',
      ]));
    });
  });

  group('Router — groups', () {
    test('group prepends prefix', () {
      router.group(prefix: '/api', routes: (r) {
        r.get('/users', _noop);
      });
      expect(router.routes.first.path, '/api/users');
    });

    test('nested groups accumulate prefixes', () {
      router.group(prefix: '/api', routes: (r) {
        r.group(prefix: '/v1', routes: (r) {
          r.get('/users', _noop);
        });
      });
      expect(router.routes.first.path, '/api/v1/users');
    });

    test('group middleware is applied to routes', () {
      final mw = _FakeMiddleware();
      router.group(prefix: '/secure', middleware: [mw], routes: (r) {
        r.get('/data', _noop);
      });
      expect(router.routes.first.middleware, contains(mw));
    });

    test('nested group middleware accumulates', () {
      final outer = _FakeMiddleware();
      final inner = _FakeMiddleware();
      router.group(prefix: '/', middleware: [outer], routes: (r) {
        r.group(prefix: '/inner', middleware: [inner], routes: (r) {
          r.get('/x', _noop);
        });
      });
      expect(router.routes.first.middleware, containsAll([outer, inner]));
    });

    test('prefix builder creates a group', () {
      router.prefix('/api/v1').group((r) {
        r.get('/hello', _noop);
      });
      expect(router.routes.first.path, '/api/v1/hello');
    });
  });

  group('Router — named routes', () {
    test('name registers route in namedRoutes', () {
      router.get('/users', _noop).name('users.index');
      expect(router.namedRoutes['users.index'], isNotNull);
    });

    test('findByName returns the route', () {
      router.get('/users/<id>', _noop).name('users.show');
      final r = router.findByName('users.show');
      expect(r, isNotNull);
      expect(r!.path, '/users/<id>');
    });

    test('findByName returns null for unknown name', () {
      expect(router.findByName('nope'), isNull);
    });

    test('url generates correct path', () {
      router.get('/users/<id>', _noop).name('users.show');
      final url = router.findByName('users.show')!.url({'id': '42'});
      expect(url, '/users/42');
    });
  });

  group('Router — route matching (tryMatch)', () {
    test('matches correct method and path', () {
      router.get('/users/<id>', _noop);
      final params = router.routes.first.tryMatch('GET', '/users/7');
      expect(params!['id'], '7');
    });

    test('returns null for wrong method', () {
      router.get('/users', _noop);
      expect(router.routes.first.tryMatch('POST', '/users'), isNull);
    });

    test('ANY matches any method', () {
      router.any('/ping', _noop);
      expect(router.routes.first.tryMatch('DELETE', '/ping'), isNotNull);
    });
  });
}

class _FakeMiddleware implements Middleware {
  @override
  Future<Response> handle(Request req, Next next) => next(req);
}
