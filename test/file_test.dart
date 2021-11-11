import 'dart:io';

import 'package:neo_pubspec/src/file.dart';
import 'package:neo_pubspec/src/structre/structre.dart';
import 'package:path/path.dart' as p hide equals;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  final Directory exampleDir = Directory("example").absolute;
  late File pubspecFile;
  setUpAll(() async {
    pubspecFile = File(p.join(exampleDir.path, "pubspec.yaml"));
    pubspecFile =
        await pubspecFile.copy(p.join(exampleDir.path, "backup.yaml"));
  });
  test("Test read pubspec", () async {
    PubspecProjectManager ppm = PubspecProjectManager(exampleDir);
    var pubspecObj = await ppm.extractPubspecData;
    expect(pubspecObj.environment.sdk, equals(">=2.14.0 <3.0.0"));
    expect(
        pubspecObj.dependencies.whereType<LocalPackageDependency>().first.name,
        equals("neo_pubspec"));
  });
  test("Test write pubspec", () async {
    PubspecProjectManager ppm = PubspecProjectManager(exampleDir);
    var pubspecObj = await ppm.extractPubspecData;
    pubspecObj.dependencies
        .add(HostedPackageDependency(name: "foo", version: "^1.0.0"));
    await ppm.savePubspecInfo(pubspecObj);
    YamlMap moddedPubspec = loadYaml(
        await File(p.join(exampleDir.path, "pubspec.yaml")).readAsString());
    YamlMap expectedPubspec = loadYaml(
        await File(p.join("test_assets", "written_result.yaml"))
            .readAsString());
    expect(moddedPubspec["dependencies"]["foo"],
        equals(expectedPubspec["dependencies"]["foo"]));
  });
  tearDownAll(() async {
    String pubspecFilePath = p.join(exampleDir.path, "pubspec.yaml");
    await File(pubspecFilePath).delete();
    pubspecFile = await pubspecFile.rename(pubspecFilePath);
  });
}
