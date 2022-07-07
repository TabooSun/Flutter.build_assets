import 'dart:async';
import 'dart:io';

import 'package:build_assets/src/commands/base_command.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:quiver/strings.dart';
import 'package:yaml/yaml.dart';

class BuildCommand extends BaseCommand<void> {
  static const String _dsStoreFileName = '.DS_Store';
  static const String _pubspecYamlFileName = 'pubspec.yaml';
  final DartFormatter _dartfmt = DartFormatter();

  @override
  String get description => 'Build assets.';

  @override
  String get name => 'build';

  @override
  Future<void>? run() async {
    final file = File(
      p.joinAll([
        await getFlutterProjectPath(),
        _pubspecYamlFileName,
      ]),
    );

    if (!file.existsSync()) {
      throw Exception('Cannot find $_pubspecYamlFileName.');
    }

    final assets = _getAssets(file);
    // ignore:unused_local_variable
    final classes = getRequiredClasses(assets);
    await _generateResFile(assets);
    print('Done building assets.');
  }

// Will be very useful when Dart supports nested class
/*Set<String> _getRequiredClasses() {
  Set<String> classes = Set();
  for (var asset in assets) {
    for (var e in p.split(asset).where((x) => isBlank(p.extension(x)))) {
      classes.add(e);
    }
  }
  return classes;
}*/

  Set<String> getRequiredClasses(List<String> assets) {
    final classes = <String>{};
    for (final asset in assets) {
      for (final e in p.split(asset).where((x) => isBlank(p.extension(x)))) {
        classes.add(e);
      }
    }
    return classes;
  }

  List<String> _getAssets(File file) {
    final pubspec = loadYaml(file.readAsStringSync());

    final List<String> assetPaths =
        (pubspec['flutter']['assets'] as List).cast<String>();

    final assets = <String>[];
    for (final assetPath in assetPaths) {
      if (assetPath.endsWith('/')) {
        final dir = Directory(assetPath);
        final files = dir.listSync(recursive: true);
        for (final x in files) {
          if (!x.path.contains(_dsStoreFileName)) assets.add(x.path);
        }
      } else {
        assets.add(assetPath);
      }
    }
    return assets.toSet().toList();
  }

  Future<void> _generateResFile(List<String> assets) async {
    final res = Class(
      (b) => b
        ..name = 'Res'
        ..fields.addAll(
          assets.map(
            (x) => Field(
              (b) => b
                ..name = p
                    .split(p.withoutExtension(x))
                    .map((y) => y.replaceAll('.', '_'))
                    .join('_')
                ..modifier = FieldModifier.constant
                ..type = refer('String')
                ..static = true
                ..assignment = Code('\'$x\''),
            ),
          ),
        ),
    );

    final generatedOutput = <String>[
      '// THIS FILE IS GENERATED AUTOMATICALLY',
      '// ignore_for_file: constant_identifier_names',
      _dartfmt.format('${res.accept(DartEmitter())}')
    ];

    const outputPath = 'lib/helpers/resources.dart';
    File(outputPath).writeAsStringSync(generatedOutput.join('\n'));
  }
}
