import 'package:shelfbase/shelfbase.dart';

import 'controllers/user_controller.dart';
import 'middleware/auth_middleware.dart';
import 'middleware/log_middleware.dart';
import 'providers/app_service_provider.dart';
import 'services/user_service.dart';

void main() async {
  // 1 — Bootstrap.
  final application = Application();

  // 2 — Register service providers (register() is called immediately;
  //     boot() is called just before listen()).
  application.register(AppServiceProvider());

  // 3 — Global middleware (applied to every request).
  application.use(LogMiddleware());

  // 4 — Routes.
  final r = application.router;

  // Health check — no auth required.
  r.get('/health', (req) => Response.json({'status': 'ok'})).name('health');

  // Public index route.
  r.get('/', (req) => Response.json({
    'framework': 'ShelfBase',
    'style': 'Laravel',
    'docs': '/health',
  })).name('home');

  // ── Authenticated API group ─────────────────────────────────────────────
  r.group(
    prefix: '/api/v1',
    middleware: [AuthMiddleware()],
    routes: (router) {
      // Full CRUD for users — maps to UserController.{index,show,store,update,destroy}
      router.resource('/users', UserController(application.make<UserService>()));

      // Named route for URL generation.
      router
          .get('/me', (req) => Response.json({'user': 'current'}))
          .name('api.me');
    },
  );

  // 5 — Start listening.
  await application.listen(port: 3000);
}
