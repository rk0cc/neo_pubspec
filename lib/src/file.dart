import 'dart:convert';
import 'dart:io';

import 'package:json2yaml/json2yaml.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'structre/structre.dart';

/// Command of execution
enum ExecuteCmd {
  /// Call `dart`
  dart,

  /// Call `flutter`
  flutter
}

/// Network mode of calling pub
enum PubNetworkMode {
  /// Get package from online only
  online,

  /// Get package from local cached
  offline
}

/// Do precompile when get or upgrade dependencies
enum PubPreCompile {
  /// Allow precompile package
  allow,

  /// Prevent precompile
  disallow
}

extension _ExecuteCmdHandler on ExecuteCmd {
  String get executable => this.toString().split(".").last;
}

extension _PubNetworkArgs on PubNetworkMode {
  String get args {
    String base = "-offline";
    switch (this) {
      case PubNetworkMode.online:
        return "--no$base";
      case PubNetworkMode.offline:
        return "-$base";
    }
  }
}

extension _PubPreCompileArgs on PubPreCompile {
  String get args {
    String base = "-precompile";
    switch (this) {
      case PubPreCompile.allow:
        return "-$base";
      case PubPreCompile.disallow:
        return "--no$base";
    }
  }
}

/// Manage `pubspec.yaml` data
class PubspecProjectManager {
  static PubspecProjectManager? _lastCreated;
  bool _flutterMode;
  late File _pubspec;

  PubspecProjectManager._(Directory projectDir) : _flutterMode = false {
    File pubspec = File(p.join(projectDir.path, "pubspec.yaml"));
    assert(pubspec.existsSync(),
        "Can not found pubspec.yaml in ${projectDir.path}");
    _pubspec = pubspec;
  }

  /// Create new [PubspecProjectManager] from project [Directory]
  ///
  /// When it called, it also save [lastCreated] if necessary.
  factory PubspecProjectManager(Directory projectDir) {
    PubspecProjectManager ppm = PubspecProjectManager._(projectDir);
    _lastCreated = ppm;
    return ppm;
  }

  void _flutterCheck(PubspecInfo info) {
    _flutterMode = info.isFlutter;
  }

  /// Extract `pubspec.yaml` data to [PubspecInfo]
  Future<PubspecInfo> get extractPubspecData async {
    String ps = await _pubspec.readAsString();
    var py = loadYaml(ps);
    if (py is YamlMap) {
      PubspecInfo info = PubspecInfoImportExport.parseFromMap<YamlMap>(py);
      _flutterCheck(info);
      return info;
    } else {
      throw TypeError();
    }
  }

  Future<String> _executePub(String action, List<String>? args) async {
    var cmdStr =
        (_flutterMode ? ExecuteCmd.flutter : ExecuteCmd.dart).executable;
    List<String> ca = ["pub", action]..addAll(args ?? []);
    var result = await Process.run(cmdStr, ca,
        workingDirectory: _pubspec.parent.absolute.path, runInShell: true);
    if (result.exitCode != 0) {
      throw ProcessException(
          cmdStr, ca, result.stderr.toString(), result.exitCode);
    }
    return result.stdout.toString();
  }

  /// Save modified [info] to `pubspec.yaml`
  Future<void> savePubspecInfo(PubspecInfo info) async {
    _flutterCheck(info);
    _pubspec = await _pubspec.writeAsString(
        json2yaml(info.toMap(), yamlStyle: YamlStyle.pubspecYaml));
  }

  /// Execute `pub get` command
  ///
  /// If [info] provided, it will execute [savePubspecInfo] first.
  ///
  /// Throws [ProcessException] if exit code return non zero
  Future<String> getPubspec(
      {PubspecInfo? info,
      PubNetworkMode? networkMode,
      PubPreCompile? preCompile,
      bool dryRun = false}) async {
    if (info != null) {
      await savePubspecInfo(info);
    }
    List<String> argList = [];
    if (networkMode != null) {
      argList.add(networkMode.args);
    }
    if (preCompile != null) {
      argList.add(preCompile.args);
    }
    if (dryRun) {
      argList.add("--dry-run");
    }
    return await _executePub("get", argList);
  }

  /// Execute `pub upgrade` command
  ///
  /// Throws [ProcessException] if exit code return non zero
  Future<String> upgradePubspec(
      {PubNetworkMode? networkMode,
      PubPreCompile? preCompile,
      bool dryRun = false,
      bool nullSafety = false,
      bool majorVersion = false}) async {
    List<String> argList = [];
    if (networkMode != null) {
      argList.add(networkMode.args);
    }
    if (preCompile != null) {
      argList.add(preCompile.args);
    }
    if (dryRun) {
      argList.add("--dry-run");
    }
    if (nullSafety) {
      argList.add("--null-safety");
    }
    if (majorVersion) {
      argList.add("--major-versions");
    }
    return await _executePub("upgrade", argList);
  }

  /// Return recent created [PubspecProjectManager]
  ///
  /// Return `null` if no [PubspecProjectManager] has been created before
  static PubspecProjectManager? get lastCreated => _lastCreated;
}

/// Handling all import and export object of [PubspecInfo]
extension PubspecInfoImportExport on PubspecInfo {
  /// Get [Map] object of [PubspecInfo]
  ///
  /// And append additional information if applied
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> pubspecMap = {
      "name": name,
      "environment": environment.map
    };
    if (description != null) {
      pubspecMap["description"] = description!;
    }
    if (publishTo != null) {
      pubspecMap["publish_to"] = publishTo!;
    }
    if (version != null) {
      pubspecMap["version"] = version!;
    }
    if (homepage != null) {
      pubspecMap["homepage"] = homepage!;
    }
    if (repository != null) {
      pubspecMap["repository"] = repository!;
    }
    if (issueTracker != null) {
      pubspecMap["issue_tracker"] = issueTracker!;
    }
    if (documentation != null) {
      pubspecMap["documentation"] = documentation!;
    }
    if (dependencies.isNotEmpty) {
      pubspecMap["dependencies"] = dependencies.toMap();
    }
    if (devDependencies.isNotEmpty) {
      pubspecMap["dev_dependencies"] = devDependencies.toMap();
    }
    if (dependencyOverrides.isNotEmpty) {
      pubspecMap["dependency_overrides"] = dependencyOverrides.toMap();
    }
    return pubspecMap..addAll(additionalProperties);
  }

  /// Parse data from [Map] object including [YamlMap]
  static PubspecInfo parseFromMap<M extends Map>(M map) => PubspecInfo(
      name: map["name"],
      environment: PubspecEnvironment(
          sdk: map["environment"]["sdk"],
          flutter: map["environment"]["flutter"]),
      publishTo: map["publish_to"],
      description: map["description"],
      version: map["version"],
      homepage: map["homepage"],
      repository: map["repository"],
      issueTracker: map["issue_tracker"],
      documentation: map["documentation"],
      dependencies:
          PackageDependencySetFactory.fromMap<PackageDependencySet, M>(
              map["dependencies"]),
      devDependencies:
          PackageDependencySetFactory.fromMap<PackageDependencySet, M>(
              map["dev_dependencies"]),
      dependencyOverrides:
          PackageDependencySetFactory.fromMap<OverridePackageDependencySet, M>(
              map["dependency_overrides"]),
      additionalProperties: AdditionalProperty(
          data: Map.from(map)
            ..removeWhere((key, value) =>
                AdditionalProperty.pubspecField.contains(key))));
}
