import 'dart:collection';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../validator.dart' as validator;

part 'dependencies.dart';

FormatException _genExceptionFromAssertError(AssertionError ae) {
  if (ae.message != null) {
    return FormatException(
        "Found invalid format", Error.safeToString(ae.message));
  }
  return FormatException("Found invalid format");
}

void _assignHandler(void Function() assign) {
  try {
    assign();
  } on AssertionError catch (ae) {
    throw _genExceptionFromAssertError(ae);
  }
}

class PubspecEnvironment {
  late String _sdk;
  late String? _flutter;

  set sdk(String newVal) => _assignHandler(() {
        assert(
            validator.hasValidatedVersioning(newVal) &&
                !RegExp(r"^\^").hasMatch(newVal),
            "$newVal can not assign as SDK version");
        _sdk = newVal;
      });

  set flutter(String? newVal) => _assignHandler(() {
        if (newVal != null) {
          assert(validator.hasValidatedVersioning(newVal),
              "$newVal is not valid version to assign Flutter");
        }
        _flutter = newVal;
      });

  String get sdk => _sdk;

  String? get flutter => _flutter;

  PubspecEnvironment({required String sdk, String? flutter}) {
    this._sdk = sdk;
    this._flutter = flutter;
  }

  Map<String, String> get map {
    Map<String, String> m = {"sdk": sdk};
    if (flutter != null) {
      m["flutter"] = flutter!;
    }
    return m;
  }
}

class PubspecInfo {
  void _publishPackageFieldValidator(String? newVal, String fieldName) {
    if (publishTo != "none") {
      assert(newVal != null, "$fieldName is required when publishing package");
    }
  }

  String? publishTo;

  late String _name;

  late String? _description,
      _version,
      _homepage,
      _repository,
      _issueTracker,
      _documentation;

  set name(String newVal) => _assignHandler(() {
        assert(validator.hasValidatedName(newVal),
            "$newVal is not valid package name");
        _name = newVal;
      });

  set description(String? newVal) {
    _publishPackageFieldValidator(newVal, "Description");
    assert(validator.hasEnoughLengthDescription(newVal!),
        "The description length must between 60 to 180 charathers");
    _description = newVal;
  }

  set version(String? newVal) {
    _publishPackageFieldValidator(newVal, "Version");
    assert(validator.hasValidatedVersioning(newVal!, dependency: false),
        "$newVal is not valid versioning");
    _version = newVal;
  }

  String get name => _name;

  String? get description => _description;

  String? get version => _version;

  final PackageDependencySet dependencies;

  final PackageDependencySet devDependencies;

  final PackageDependencySet dependencyOverrides;

  PubspecInfo(
      {this.publishTo,
      PackageDependencySet? dependencies,
      PackageDependencySet? devDependencies,
      PackageDependencySet? dependencyOverrides,
      required String name})
      : dependencies = dependencies ?? PackageDependencySet(),
        devDependencies = devDependencies ?? PackageDependencySet(),
        dependencyOverrides = dependencyOverrides ?? PackageDependencySet() {
    this.name = name;
  }
}
