import 'package:shelfbase/shelfbase.dart';

/// Logs each request method, path, and response status to stdout.
class LogMiddleware implements Middleware {
  @override
  Future<Response> handle(Request request, Next next) async {
    final watch = Stopwatch()..start();
    final response = await next(request);
    watch.stop();
    print(
      '[LOG] ${request.method.padRight(7)} '
      '${request.path.padRight(30)} '
      '${response.statusCode}  '
      '${watch.elapsedMilliseconds}ms',
    );
    return response;
  }
}
