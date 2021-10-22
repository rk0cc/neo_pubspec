import 'dart:collection';
import 'dart:io';

import 'package:pub_semver/pub_semver.dart';
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

/// Environment configuration field from `pubspec.yaml`
class PubspecEnvironment {
  late String _sdk;
  late String? _flutter;

  /// Set Dart SDK version
  ///
  /// Please note that you can not assign caret syntax (`^`) in this field
  set sdk(String newVal) => _assignHandler(() {
        assert(
            validator.hasValidatedVersioning(newVal) &&
                !RegExp(r"^\^").hasMatch(newVal),
            "$newVal can not assign as SDK version");
        _sdk = newVal;
      });

  /// Set Flutter SDK version
  set flutter(String? newVal) => _assignHandler(() {
        if (newVal != null) {
          assert(validator.hasValidatedVersioning(newVal),
              "$newVal is not valid version to assign Flutter");
        }
        _flutter = newVal;
      });

  /// Get Dart SDK version
  String get sdk => _sdk;

  /// Get Flutter SDK version
  String? get flutter => _flutter;

  /// Create new record of [PubspecEnvironment]
  PubspecEnvironment({required String sdk, String? flutter}) {
    this.sdk = sdk;
    this.flutter = flutter;
  }

  /// Convert it [Map] as value of `pubspec.yaml`
  Map<String, String> get map {
    final Map<String, String> m = {"sdk": sdk};
    if (flutter != null) {
      m["flutter"] = flutter!;
    }
    return m;
  }
}

/// Object of `pubspec.yaml` context
///
/// Only shared field will be included this object, any unique field
/// like `flutter` or `executables` will be stored as private property
/// until export
class PubspecInfo {
  void _publishPackageFieldValidator(String? newVal, String fieldName) {
    if (publishTo != "none") {
      assert(newVal != null, "$fieldName is required when publishing package");
    }
  }

  /// Storing additinal field in this field until convert back to map
  final Map<String, dynamic> _additionalProperties = {};

  /// Target site of publishing package
  ///
  /// Assign `"none"` if keep this package private
  ///
  /// Assign `null` for publishing to [pub.dev](https://pub.dev)
  String? publishTo;

  /// Environemnt field
  final PubspecEnvironment environment;

  /// Package that will be used in your project
  final PackageDependencySet dependencies;

  /// Package that will be used in your project for testing
  final PackageDependencySet devDependencies;

  /// Apply the package that planning to be overrided
  final OverridePackageDependencySet dependencyOverrides;

  late String _name;

  late String? _description,
      _version,
      _homepage,
      _repository,
      _issueTracker,
      _documentation;

  /// Package's name
  set name(String newVal) => _assignHandler(() {
        assert(validator.hasValidatedName(newVal),
            "$newVal is not valid package name");
        _name = newVal;
      });

  /// Package's description
  ///
  /// It is non-null field when [publishTo] is not `"none"`
  set description(String? newVal) => _assignHandler(() {
        _publishPackageFieldValidator(newVal, "Description");
        assert(validator.hasEnoughLengthDescription(newVal!),
            "The description length must between 60 to 180 charathers");
        _description = newVal;
      });

  /// Package's version
  ///
  /// It is non-null field when [publishTo] is not `"none"`
  set version(String? newVal) => _assignHandler(() {
        _publishPackageFieldValidator(newVal, "Version");
        assert(validator.hasValidatedVersioning(newVal!, dependency: false),
            "$newVal is not valid versioning");
        _version = newVal;
      });

  /// Provide homepage of the package owner
  set homepage(String? newVal) => _assignHandler(() {
        if (newVal != null) {
          assert(validator.hasValidateHttpFormat(newVal),
              "$newVal is not valid homepage website");
        }
        _homepage = newVal;
      });

  /// Provide a link to package's repository
  set repository(String? newVal) => _assignHandler(() {
        if (newVal != null) {
          assert(validator.hasValidateHttpFormat(newVal),
              "$newVal is not valid repository website");
        }
        _repository = newVal;
      });

  /// Provide a issue page of this package
  set issueTracker(String? newVal) => _assignHandler(() {
        if (newVal != null) {
          assert(validator.hasValidateHttpFormat(newVal),
              "$newVal is not valid issue tracker website");
        }
        _issueTracker = newVal;
      });

  /// Provide documentation of this package
  set documentation(String? newVal) => _assignHandler(() {
        if (newVal != null) {
          assert(validator.hasValidateHttpFormat(newVal),
              "$newVal is not valid documentation website");
        }
        _documentation = newVal;
      });

  /// Get package [name]
  String get name => _name;

  /// Get package [description]
  String? get description => _description;

  /// Get package [version]
  String? get version => _version;

  /// Get package [homepage]
  String? get homepage => _homepage;

  /// Get package [repository] site
  String? get repository => _repository;

  /// Get package [issueTracker]
  String? get issueTracker => _issueTracker;

  /// Get package [documentation] site
  String? get documentation => _documentation;

  /// Create new [PubspecInfo] object
  PubspecInfo(
      {this.publishTo,
      PackageDependencySet? dependencies,
      PackageDependencySet? devDependencies,
      OverridePackageDependencySet? dependencyOverrides,
      required String name,
      required this.environment})
      : dependencies = dependencies ?? PackageDependencySet(),
        devDependencies = devDependencies ?? PackageDependencySet(),
        dependencyOverrides =
            dependencyOverrides ?? OverridePackageDependencySet() {
    this.name = name;
  }
}

extension PubspecInfoImportExport on PubspecInfo {
  static Future<PubspecInfo> loadFromDir(Directory projectDir) async {
    throw UnimplementedError();
  }

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
    return pubspecMap..addAll(_additionalProperties);
  }
}
