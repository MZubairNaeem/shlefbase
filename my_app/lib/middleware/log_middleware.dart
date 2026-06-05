import 'package:shelfbase/shelfbase.dart';

class LogMiddleware implements Middleware {
  @override
  Future<Response> handle(Request request, Next next) async {
    final watch = Stopwatch()..start();
    final response = await next(request);
    watch.stop();
    print(
      '[LOG] ${request.method.padRight(7)} '
      '${request.path.padRight(35)} '
      '${response.statusCode}  '
      '${watch.elapsedMilliseconds}ms',
    );
    return response;
  }
}
