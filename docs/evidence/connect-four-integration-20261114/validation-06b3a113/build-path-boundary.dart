import 'dart:convert';
import 'package:file/local.dart';

void main() {
  const fs = LocalFileSystem();
  final root = fs.systemTempDirectory.createTempSync('lumo-c4-build-path-proof-');
  final results = <Map<String, Object?>>[];
  for (final parentLink in [false, true]) {
    final caseRoot = root.childDirectory(parentLink ? 'parent-link' : 'child-link')..createSync();
    final work = caseRoot.childDirectory('work')..createSync();
    final external = caseRoot.childDirectory('external')..createSync();
    final buildPath = '${work.path}/build';
    final bundlePath = '$buildPath/unit_test_assets';
    final linkPath = parentLink ? buildPath : bundlePath;
    if (parentLink) {
      fs.link(buildPath).createSync(external.path);
      fs.directory(bundlePath).createSync();
    } else {
      fs.directory(buildPath).createSync();
      fs.link(bundlePath).createSync(external.path);
    }
    fs.file('$bundlePath/before.txt').writeAsStringSync('old');
    final bundleDir = fs.directory(bundlePath);
    // Verbatim operations used by this installed Flutter writeBundle boundary.
    if (bundleDir.existsSync()) bundleDir.deleteSync(recursive: true);
    bundleDir.createSync(recursive: true);
    final file = fs.file('$bundlePath/after.txt')..writeAsStringSync('new');
    final physical = file.resolveSymbolicLinksSync();
    final linkSurvives = fs.link(linkPath).existsSync();
    final remainsExternal = physical.startsWith('${external.path}/');
    if (parentLink != linkSurvives || parentLink != remainsExternal) {
      throw StateError('Unexpected filesystem boundary');
    }
    results.add({'case':parentLink?'parent-link':'child-link','link_survives':linkSurvives,
      'file_remains_external':remainsExternal,'resolved_file':physical});
  }
  print(jsonEncode({'passed':true,'scope':'Empty local filesystem boundary only; no Flutter/App/Renderer test',
    'results':results}));
  root.deleteSync(recursive:true);
}
