/// Laravel-style IoC container.
///
/// Supports three registration modes:
///   - [bind]      — new instance on every [make] call
///   - [singleton] — single shared instance (lazy, created on first [make])
///   - [instance]  — pre-built value registered directly
///
/// ```dart
/// container.singleton<DatabaseService>(
///   (c) => DatabaseService(url: c.make<Config>().dbUrl),
/// );
///
/// final db = container.make<DatabaseService>();
/// ```
class Container {
  final Map<Type, _Binding<dynamic>> _bindings = {};

  /// Register a factory that produces a **new** instance on every [make].
  void bind<T>(T Function(Container c) factory) {
    _bindings[T] = _Binding<T>(factory, singleton: false);
  }

  /// Register a factory whose result is cached and reused on every [make].
  void singleton<T>(T Function(Container c) factory) {
    _bindings[T] = _Binding<T>(factory, singleton: true);
  }

  /// Register an already-constructed [value] as a singleton.
  void instance<T>(T value) {
    final binding = _Binding<T>((_) => value, singleton: true);
    binding._instance = value;
    _bindings[T] = binding;
  }

  /// Resolve an instance of [T].
  ///
  /// Throws [StateError] if nothing is bound for [T].
  T make<T>() {
    final b = _bindings[T] as _Binding<T>?;
    if (b == null) {
      throw StateError(
        'Nothing bound for type $T. '
        "Call app.bind<$T>() or app.singleton<$T>() first.",
      );
    }
    return b.resolve(this);
  }

  /// Whether a binding exists for [T].
  bool bound<T>() => _bindings.containsKey(T);

  /// Override an existing binding (useful in tests).
  void rebind<T>(T Function(Container c) factory, {bool singleton = true}) {
    _bindings[T] = _Binding<T>(factory, singleton: singleton);
  }
}

// ── Internal ──────────────────────────────────────────────────────────────

class _Binding<T> {
  final T Function(Container) _factory;
  final bool _singleton;
  T? _instance;

  _Binding(this._factory, {required bool singleton}) : _singleton = singleton;

  T resolve(Container c) {
    if (_singleton) return _instance ??= _factory(c);
    return _factory(c);
  }
}
