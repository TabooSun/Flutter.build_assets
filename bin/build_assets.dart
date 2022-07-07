import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:build_assets/src/commands/base_command.dart';
import 'package:build_assets/src/commands/build_command.dart';

Future<void> main(List<String> arguments) async {
  final commandRunner = CommandRunner(
    'buildasset',
    'A tool to build Flutter assets. This generates a resources.dart file in lib/helpers of your Flutter project.',
  )..addCommand(BuildCommand());
  commandRunner.argParser.addOption(
    BaseCommand.projectPathToken,
    abbr: 'p',
    help: 'The project path.',
    mandatory: false,
  );
  try {
    await commandRunner.run(arguments);
  } catch (ex, stackTrace) {
    _handleException(
      ex: ex,
      stackTrace: stackTrace,
      parser: commandRunner.argParser,
    );
  }
}

void _handleException({
  dynamic ex,
  required StackTrace stackTrace,
  required ArgParser parser,
}) {
  final sb = StringBuffer();
  if (ex is String) {
    sb.writeln(ex);
  } else if (ex is FormatException) {
    sb.writeln(ex.message);
  } else {
    print(ex);
    print(stackTrace);
  }

  sb.writeln();
  sb.writeln(parser.usage);
  print(sb.toString());
}

Future<void> executeAsync({
  required ArgParser argParser,
}) async {}
