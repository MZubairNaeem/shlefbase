import 'package:shelfbase/shelfbase.dart';
import 'package:test/test.dart';

void main() {
  group('RoutePattern', () {
    group('match', () {
      test('matches exact static path', () {
        final p = RoutePattern('/users');
        expect(p.match('/users'), isNotNull);
        expect(p.match('/users/'), isNull);
        expect(p.match('/user'), isNull);
      });

      test('matches root path', () {
        expect(RoutePattern('/').match('/'), isNotNull);
      });

      test('matches single param and extracts it', () {
        final p = RoutePattern('/users/<id>');
        final m = p.match('/users/42');
        expect(m, isNotNull);
        expect(m!['id'], '42');
      });

      test('matches multiple params', () {
        final p = RoutePattern('/posts/<postId>/comments/<commentId>');
        final m = p.match('/posts/7/comments/99');
        expect(m!['postId'], '7');
        expect(m['commentId'], '99');
      });

      test('does not match with too many segments', () {
        expect(RoutePattern('/users/<id>').match('/users/42/extra'), isNull);
      });

      test('does not match with too few segments', () {
        expect(RoutePattern('/users/<id>').match('/users'), isNull);
      });

      test('greedy param captures slashes', () {
        final p = RoutePattern('/files/<path:*>');
        final m = p.match('/files/a/b/c.txt');
        expect(m!['path'], 'a/b/c.txt');
      });
    });

    group('url generation', () {
      test('substitutes single param', () {
        final p = RoutePattern('/users/<id>');
        expect(p.url({'id': '42'}), '/users/42');
      });

      test('substitutes multiple params', () {
        final p = RoutePattern('/posts/<postId>/comments/<commentId>');
        expect(p.url({'postId': '7', 'commentId': '99'}),
            '/posts/7/comments/99');
      });

      test('leaves unresolved params as-is', () {
        final p = RoutePattern('/users/<id>');
        expect(p.url({}), '/users/<id>');
      });
    });

    group('matches helper', () {
      test('returns true for matching path', () {
        expect(RoutePattern('/users/<id>').matches('/users/1'), isTrue);
      });

      test('returns false for non-matching path', () {
        expect(RoutePattern('/users/<id>').matches('/products/1'), isFalse);
      });
    });
  });
}
