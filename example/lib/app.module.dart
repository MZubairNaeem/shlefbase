import 'package:shelfbase/shelfbase.dart';

import 'users/user.controller.dart';
import 'users/user.service.dart';

/// Root application module.
///
/// - [providers]   declares services for the DI container
/// - [controllers] tells ShelfBase how to build and mount each controller
///
/// In Phase 1, wiring is explicit: [ControllerFactory] receives the container
/// and pulls its own dependencies.  Phase 2 codegen will replace this with a
/// generated file so only the @Module annotation is needed.
@Module(
  controllers: [UserController],
  providers: [UserService],
)
class AppModule extends ShelfBaseModule {
  @override
  List<Provider<dynamic>> get providers => [
        Provider<UserService>(() => UserService()),
      ];

  @override
  List<ControllerFactory<dynamic>> get controllers => [
        ControllerFactory<UserController>(
          (c) => UserController(c.get<UserService>()),
        ),
      ];
}
