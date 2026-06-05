import 'package:shelfbase/shelfbase.dart';

import '../validation/validation_exception.dart';

/// Catches [ValidationException] thrown by DTOs and returns a 422 response.
///
/// Apply globally so any controller that uses a DTO gets validation errors
/// serialised automatically without extra try/catch in every handler.
class ValidateMiddleware implements Middleware {
  @override
  Future<Response> handle(Request request, Next next) async {
    try {
      return await next(request);
    } on ValidationException catch (e) {
      return Response.unprocessable(e.errors);
    }
  }
}
