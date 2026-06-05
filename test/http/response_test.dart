import 'dart:convert';

import 'package:shelfbase/shelfbase.dart';
import 'package:test/test.dart';

Future<dynamic> _decode(Response r) async =>
    jsonDecode(await r.toShelf().readAsString());

void main() {
  group('Response', () {
    group('status codes', () {
      test('json defaults to 200', () {
        expect(Response.json({}).statusCode, 200);
      });
      test('created is 201', () {
        expect(Response.created({}).statusCode, 201);
      });
      test('noContent is 204', () {
        expect(Response.noContent().statusCode, 204);
      });
      test('redirect is 302 by default', () {
        expect(Response.redirect('/home').statusCode, 302);
      });
      test('redirect accepts custom status', () {
        expect(Response.redirect('/home', status: 301).statusCode, 301);
      });
      test('badRequest is 400', () {
        expect(Response.badRequest().statusCode, 400);
      });
      test('unauthorized is 401', () {
        expect(Response.unauthorized().statusCode, 401);
      });
      test('forbidden is 403', () {
        expect(Response.forbidden().statusCode, 403);
      });
      test('notFound is 404', () {
        expect(Response.notFound().statusCode, 404);
      });
      test('unprocessable is 422', () {
        expect(Response.unprocessable([]).statusCode, 422);
      });
      test('serverError is 500', () {
        expect(Response.serverError().statusCode, 500);
      });
    });

    group('json body', () {
      test('encodes map', () async {
        final body = await _decode(Response.json({'key': 'value'}));
        expect(body['key'], 'value');
      });

      test('encodes list', () async {
        final body = await _decode(Response.json([1, 2, 3]));
        expect(body, [1, 2, 3]);
      });

      test('sets content-type header', () {
        final r = Response.json({});
        expect(r.headers['content-type'], contains('application/json'));
      });
    });

    group('text / html', () {
      test('text sets correct content-type', () {
        final r = Response.text('hello');
        expect(r.headers['content-type'], contains('text/plain'));
      });
      test('html sets correct content-type', () {
        final r = Response.html('<h1>hi</h1>');
        expect(r.headers['content-type'], contains('text/html'));
      });
    });

    group('builder (withHeader / withStatus)', () {
      test('withHeader adds header', () {
        final r = Response.json({}).withHeader('X-Foo', 'bar');
        expect(r.headers['x-foo'], 'bar');
      });

      test('withHeader is immutable (original unchanged)', () {
        final original = Response.json({});
        original.withHeader('X-Foo', 'bar');
        expect(original.headers.containsKey('x-foo'), isFalse);
      });

      test('withStatus changes status code', () {
        final r = Response.json({}).withStatus(202);
        expect(r.statusCode, 202);
      });
    });

    group('redirect', () {
      test('sets location header', () {
        final r = Response.redirect('/dashboard');
        expect(r.headers['location'], '/dashboard');
      });
    });

    group('toShelf', () {
      test('converts to shelf.Response', () {
        final shelf = Response.json({'ok': true}).toShelf();
        expect(shelf.statusCode, 200);
        expect(shelf.headers['content-type'], contains('application/json'));
      });
    });
  });
}
