import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as p;

abstract class BaseCommand<T> extends Command<T> {
  static const String _flutterRootProjectSentinel = 'pubspec.yaml';
  static const String projectPathToken = 'path';

  Future<String> getFlutterProjectPath() async {
    final globalResults = this.globalResults!;
    String? projectPath;

    if (globalResults.wasParsed(projectPathToken)) {
      projectPath = globalResults[projectPathToken] as String?;
    }

    if (projectPath == null) {
      return _findFlutterProjectPath();
    }

    if (await _checkForFlutterRootProjectSentinel(projectPath)) {
      return projectPath;
    }

    throw ArgumentError(
      'Invalid flutter project. No $_flutterRootProjectSentinel found.',
    );
  }

  Future<bool> _checkForFlutterRootProjectSentinel(String projectPath) {
    return const LocalFileSystem()
        .isFile(p.joinAll([projectPath, _flutterRootProjectSentinel]));
  }

  Future<String> _findFlutterProjectPath() async {
    Directory projectDirectory = const LocalFileSystem().currentDirectory;
    while (true) {
      final projectPath = projectDirectory.path;
      if (await _checkForFlutterRootProjectSentinel(projectPath)) {
        return projectPath;
      }

      final parent = projectDirectory.parent;
      if (parent == projectDirectory) {
        throw ArgumentError('Unable to find flutter project.');
      }

      projectDirectory = projectDirectory.parent;
    }
  }
}
