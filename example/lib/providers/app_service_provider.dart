import 'package:shelfbase/shelfbase.dart';

import '../services/user_service.dart';

/// Registers application services into the IoC container.
class AppServiceProvider extends ServiceProvider {
  @override
  void register() {
    // Singleton — same UserService instance reused for every request.
    app.singleton<UserService>((_) => UserService());
  }

  @override
  Future<void> boot() async {
    // Perform any async setup here (e.g. open DB connections).
  }
}
