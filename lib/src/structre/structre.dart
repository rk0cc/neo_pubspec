import 'dart:collection';

import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

import '../validator.dart' as validator;

part 'dependencies.dart';

/// Indicate this [Object] can be cloned with same value but different memory
/// location object
///
/// Please keep this mixin not public
mixin _Clonable {
  /// Generate new [Object] with delicated memory location
  ///
  /// This allows to perform
  /// [Memento Pattern](https://en.wikipedia.org/wiki/Memento_pattern) that the
  /// variable will not shared the same location which allowing save difference
  /// when doing changed.
  // ignore: unused_element
  Object get _clone;
}

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
class PubspecEnvironment with _Clonable {
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

  @override
  PubspecEnvironment get _clone =>
      PubspecEnvironment(sdk: this._sdk, flutter: this._flutter);
}

/// A [Map] data that is not defined in [PubspecInfo]
///
/// It may be `executables` or `flutter` that on-demand field
class AdditionalProperty extends MapBase<String, dynamic> with _Clonable {
  final Map<String, dynamic> _map = {};

  /// The [Set] that you can not assign in [AdditionalProperty] since they
  /// provided in [PubspecInfo]
  static const Set<String> pubspecField = const {
    "name",
    "environment",
    "description",
    "publish_to",
    "homepage",
    "repository",
    "issue_tracker",
    "version",
    "documentation",
    "dependencies",
    "dev_dependencies",
    "dependency_overrides"
  };

  static void _fieldKeyCheck(String afk) {
    var dfiaf = pubspecField.where((element) => element == afk);
    if (dfiaf.isNotEmpty || !RegExp(r"^[a-z_]+$").hasMatch(afk)) {
      throw FormatException("Field $afk can not apply here");
    }
  }

  AdditionalProperty({Map<dynamic, dynamic>? data}) {
    if (data != null) {
      data.forEach((key, _) => _fieldKeyCheck(key));
      _map.addAll(Map.from(data));
    }
  }

  @override
  operator [](Object? key) => _map[key];

  @override
  void operator []=(String key, value) {
    _fieldKeyCheck(key);
    _map[key] = value;
  }

  @override
  void clear() => _map.clear();

  @override
  Iterable<String> get keys => _map.keys;

  @override
  remove(Object? key) => _map.remove(key);

  @override
  AdditionalProperty get _clone => AdditionalProperty(data: _map);
}

/// Object of `pubspec.yaml` context
///
/// Only shared field will be included this object, any unique field
/// like `flutter` or `executables` will be stored as private property
/// until export
class PubspecInfo with _Clonable {
  void _publishPackageFieldValidator(String? newVal, String fieldName) {
    if (publishTo != "none") {
      assert(newVal != null, "$fieldName is required when publishing package");
    }
  }

  /// Storing additinal field in this field until convert back to map
  final AdditionalProperty additionalProperties;

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
        assert(
            validator.hasEnoughLengthDescription(newVal ?? "",
                privatePackage: publishTo == "none"),
            "The description length must between 60 to 180 charathers");
        _description = newVal;
      });

  /// Package's version
  ///
  /// It is non-null field when [publishTo] is not `"none"`
  set version(String? newVal) => _assignHandler(() {
        _publishPackageFieldValidator(newVal, "Version");
        if (publishTo != "none") {
          assert(validator.hasValidatedVersioning(newVal!, dependency: false),
              "$newVal is not valid versioning");
        }
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
      AdditionalProperty? additionalProperties,
      required String name,
      required this.environment,
      String? description,
      String? version,
      String? homepage,
      String? repository,
      String? issueTracker,
      String? documentation})
      : dependencies = dependencies ?? PackageDependencySet(),
        devDependencies = devDependencies ?? PackageDependencySet(),
        dependencyOverrides =
            dependencyOverrides ?? OverridePackageDependencySet(),
        additionalProperties = additionalProperties ?? AdditionalProperty() {
    this.name = name;
    this.description = description;
    this.version = version;
    this.homepage = homepage;
    this.repository = repository;
    this.issueTracker = issueTracker;
    this.documentation = documentation;
  }

  /// Clone entire [pubspecInfo] data
  ///
  /// Ensure all [PubspecInfo] field is valid, otherwise throw [AssertionError]
  /// if found at least one invalid field on [clone].
  @override
  PubspecInfo get _clone => PubspecInfo(
      name: _name,
      environment: environment._clone,
      publishTo: publishTo,
      version: _version,
      description: _description,
      homepage: _homepage,
      repository: _repository,
      issueTracker: _issueTracker,
      documentation: _documentation,
      dependencies: dependencies._clone,
      devDependencies: devDependencies._clone,
      dependencyOverrides: dependencyOverrides._clone,
      additionalProperties: additionalProperties._clone);
}

/// Condition of checking is a flutter project
extension FlutterPubspecCondition on PubspecInfo {
  /// Determine is a flutter project by inspecting dependencies in
  /// [PubspecInfo]
  bool get isFlutter =>
      dependencies.contains(SDKPackageDependency.flutter(name: "flutter"));
}

/// Cloning entire [PubspecInfo]
extension PubspecInfoCloner on PubspecInfo {
  /// Generate deep cloned [PubspecInfo]
  PubspecInfo get clone => _clone;
}
