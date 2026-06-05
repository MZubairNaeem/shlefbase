import 'dart:io';

import 'package:shelfbase/src/cli/cli_runner.dart';

Future<void> main(List<String> args) async {
  final code = await CliRunner().run(args);
  exit(code);
}
