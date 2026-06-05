import '../generator_context.dart';
import 'generator_base.dart';

abstract final class ServiceGenerator {
  static Future<bool> generate(
    GeneratorContext ctx, {
    bool dryRun = false,
    bool force = false,
  }) {
    return GeneratorBase.writeFile(
      ctx.filePath('service'),
      _template(ctx),
      dryRun: dryRun,
      force: force,
    );
  }

  static String _template(GeneratorContext ctx) => '''
class ${ctx.className}Service {
  final List<Map<String, dynamic>> _store = [];

  List<Map<String, dynamic>> findAll() => List.unmodifiable(_store);

  Map<String, dynamic>? findOne(String id) {
    try {
      return _store.firstWhere((item) => item['id'] == id);
    } on StateError {
      return null;
    }
  }

  Map<String, dynamic> create(Map<String, dynamic> data) {
    final item = {'id': (_store.length + 1).toString(), ...data};
    _store.add(item);
    return item;
  }

  Map<String, dynamic>? update(String id, Map<String, dynamic> data) {
    final index = _store.indexWhere((item) => item['id'] == id);
    if (index == -1) return null;
    _store[index] = {..._store[index], ...data, 'id': id};
    return _store[index];
  }

  bool remove(String id) {
    final index = _store.indexWhere((item) => item['id'] == id);
    if (index == -1) return false;
    _store.removeAt(index);
    return true;
  }
}
''';
}
