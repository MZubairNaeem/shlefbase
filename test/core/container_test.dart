import 'package:shelfbase/shelfbase.dart';
import 'package:test/test.dart';

class _ServiceA {}

class _ServiceB {
  final _ServiceA a;
  _ServiceB(this.a);
}

class _Counter {
  int value = 0;
}

void main() {
  group('Container', () {
    late Container c;
    setUp(() => c = Container());

    test('bind creates a new instance on every make', () {
      c.bind<_ServiceA>((_) => _ServiceA());
      final x = c.make<_ServiceA>();
      final y = c.make<_ServiceA>();
      expect(identical(x, y), isFalse);
    });

    test('singleton returns the same instance on every make', () {
      c.singleton<_ServiceA>((_) => _ServiceA());
      expect(identical(c.make<_ServiceA>(), c.make<_ServiceA>()), isTrue);
    });

    test('instance registers a pre-built value', () {
      final svc = _ServiceA();
      c.instance<_ServiceA>(svc);
      expect(identical(c.make<_ServiceA>(), svc), isTrue);
    });

    test('resolves a dependency chain', () {
      c.singleton<_ServiceA>((_) => _ServiceA());
      c.singleton<_ServiceB>((c) => _ServiceB(c.make<_ServiceA>()));
      expect(c.make<_ServiceB>().a, isA<_ServiceA>());
    });

    test('throws StateError for unbound type', () {
      expect(() => c.make<_ServiceA>(), throwsA(isA<StateError>()));
    });

    test('bound returns true after registration', () {
      c.singleton<_ServiceA>((_) => _ServiceA());
      expect(c.bound<_ServiceA>(), isTrue);
    });

    test('bound returns false for unknown type', () {
      expect(c.bound<_ServiceA>(), isFalse);
    });

    test('rebind replaces existing registration', () {
      c.singleton<_Counter>((_) => _Counter()..value = 1);
      c.rebind<_Counter>((_) => _Counter()..value = 99);
      expect(c.make<_Counter>().value, 99);
    });
  });
}
