import 'package:shelfbase/shelfbase.dart';

/// Rejects POST/PUT/PATCH requests that don't carry a JSON body.
class JsonMiddleware implements Middleware {
  static const _mutating = {'POST', 'PUT', 'PATCH'};

  @override
  Future<Response> handle(Request request, Next next) async {
    if (_mutating.contains(request.method) && !request.isJson) {
      return Response.badRequest(
        'Content-Type must be application/json.',
      );
    }
    return next(request);
  }
}
