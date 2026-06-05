import 'package:shelfbase/shelfbase.dart';

/// Toy bearer-token guard.  Replace with real JWT validation in production.
class AuthMiddleware implements Middleware {
  static const _validToken = 'secret-token';

  @override
  Future<Response> handle(Request request, Next next) async {
    final token = request.bearerToken;
    if (token != _validToken) {
      return Response.unauthorized('Invalid or missing Bearer token');
    }
    return next(request);
  }
}
