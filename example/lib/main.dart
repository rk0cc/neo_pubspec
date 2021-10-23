import 'dart:io';

import 'package:neo_pubspec/neo_pubspec.dart';

void main() async {
  // Read existed pubspec.yaml
  PubspecProjectManager ppm = PubspecProjectManager(Directory("./"));
  PubspecInfo info = await ppm.extractPubspecData;
  print(info.toMap());

  // Call upgrade
  print(await ppm.upgradePubspec());

  // Add package
  info.dependencies
      .add(HostedPackageDependency(name: "path", version: "^1.8.0"));

  // Print updated package
  print(info.toMap());

  // Save pubspec
  await ppm.savePubspecInfo(info);

  // Get package
  print(await ppm.getPubspec());

  // Remove package
  info.dependencies.remove("path");

  // Save pubspec
  await ppm.savePubspecInfo(info);

  // Get package
  print(await ppm.getPubspec());
}
