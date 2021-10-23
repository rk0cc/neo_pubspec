part of 'structre.dart';

/// Providing [SetBase] of [PackageDependency]
///
/// It can be import or export [Map] data
abstract class PackageDependencySetFactory extends SetBase<PackageDependency> {
  /// Return [bool] of handling [dependency] with providing [e]
  static bool _iterableCondition(PackageDependency dependency, e) {
    if (e is String) {
      return e == dependency.name;
    } else if (e is PackageDependency) {
      return e == dependency;
    }
    return false;
  }

  /// Set of dependency
  final LinkedHashSet<PackageDependency> _dependencies =
      LinkedHashSet(equals: (d1, d2) => d1 == d2, hashCode: (d) => d.hashCode);

  /// Setup [PackageDependencySetFactory]
  ///
  /// It can [import] existed [Iterable] of [PackageDependency]
  PackageDependencySetFactory([Iterable<PackageDependency>? import]) {
    if (import != null) {
      _dependencies.addAll(import);
    }
  }

  /// Import pubspec data from [map]
  ///
  /// [map]'s type [M] can be either [Map] or [YamlMap]
  ///
  /// If using native [Map], the [Map]'s key must be [String]
  ///
  /// Throws [TypeError] if [M] is not a valid type which mentioned before.
  ///
  /// The return type [P] can be either [PackageDependencySet] or
  /// [OverridePackageDependencySet], but you can not assingn
  /// [PackageDependencySetFactory].
  ///
  /// Throws [UnimplementedError] if the new child
  /// class of [PackageDependencySetFactory] is created but not available to
  /// generate the object.
  static P fromMap<P extends PackageDependencySetFactory, M>(M? map) {
    assert(P != PackageDependencySetFactory,
        "This is an factory class which you can't use");
    List<PackageDependency> temp = [];
    if (map is Map<String, dynamic> || map is YamlMap) {
      (map as Map).forEach((packageName, packageInfo) {
        if (packageInfo == null || packageInfo is String) {
          // Oridinary pub.dev package
          temp.add(
              HostedPackageDependency(name: packageName, version: packageInfo));
        } else if (packageInfo is Map) {
          try {
            if (packageInfo["hosted"] != null) {
              // Third-party hosted
              assert(packageInfo["git"] == null &&
                  packageInfo["path"] == null &&
                  packageInfo["sdk"] == null);
              temp.add(ThirdPartyHostedPackageDependency(
                  name: packageName,
                  version: packageInfo["version"],
                  hostedPackageName: packageInfo["hosted"]["name"],
                  hostedUrl: packageInfo["hosted"]["url"]));
            } else if (packageInfo["git"] != null) {
              // Git hosted
              assert(packageInfo["hosted"] == null &&
                  packageInfo["path"] == null &&
                  packageInfo["sdk"] == null);
              assert(packageInfo["version"] == null);
              temp.add((packageInfo["git"] is String)
                  ? GitPackageDependency(
                      name: packageName, gitUrl: packageInfo["git"])
                  : GitPackageDependency(
                      name: packageName,
                      gitUrl: packageInfo["git"]["url"],
                      gitPath: packageInfo["git"]["path"],
                      gitRef: packageInfo["git"]["ref"]));
            } else if (packageInfo["path"] != null) {
              // Local package
              assert(packageInfo["git"] == null &&
                  packageInfo["hosted"] == null &&
                  packageInfo["sdk"] == null);
              assert(packageInfo["path"] is String);
              assert(packageInfo["version"] == null);
              temp.add(LocalPackageDependency(
                  name: packageName, packagePath: packageInfo["path"]));
            } else if (packageInfo["sdk"] != null) {
              // SDK package
              assert(packageInfo["git"] == null &&
                  packageInfo["path"] == null &&
                  packageInfo["hosted"] == null);
              assert(packageInfo["sdk"] is String);
              temp.add((packageInfo["sdk"] == "flutter")
                  ? SDKPackageDependency.flutter(
                      name: packageName, version: packageInfo["version"])
                  : SDKPackageDependency(
                      name: packageName, sdk: packageInfo["sdk"]));
            }
          } on AssertionError catch (ae) {
            throw FormatException(
                "Found invalid package field info", ae.message);
          }
        }
      });
    } else if (map != null) {
      throw TypeError();
    }

    switch (P) {
      case PackageDependencySet:
        return PackageDependencySet(import: temp) as P;
      case OverridePackageDependencySet:
        return OverridePackageDependencySet(import: temp) as P;
      default:
        throw UnimplementedError("Type ${P.toString()} is not ready yet");
    }
  }

  /// Add [PackageDependency] into [Set]
  ///
  /// Unlike [contains], [lookup] and [remove], this [value] must be
  /// [PackageDependency]
  @override
  bool add(PackageDependency value) => _dependencies.add(value);

  /// Check [element] is [contains] in this [Set]
  ///
  /// [element] can be a [String] and [PackageDependency]
  @override
  bool contains(Object? element) =>
      _dependencies.where((de) => _iterableCondition(de, element)).isNotEmpty;

  /// Get [Iterator] of this [Set]
  @override
  Iterator<PackageDependency> get iterator => _dependencies.iterator;

  /// Return count of [Set] items
  @override
  int get length => _dependencies.length;

  /// Find [PackageDependency] with [element]
  ///
  /// Returns [PackageDependency] if found or `null` if not. Since it is
  /// [SetBase], the data must be unique and also return `null` if found more
  /// than one [PackageDependency] in the [Set]
  ///
  /// [element] can be a [String] and [PackageDependency]
  @override
  PackageDependency? lookup(Object? element) {
    try {
      return _dependencies.singleWhere((de) => _iterableCondition(de, element));
    } on StateError {
      return null;
    }
  }

  /// Remove [PackageDependency] by providing [value]
  ///
  /// [value] can be either [String] or [PackageDependency]
  @override
  bool remove(Object? value) => _dependencies.remove(lookup(value));

  /// Export native [Set] object from this
  @override
  Set<PackageDependency> toSet() => _dependencies.toSet();

  /// Export [Map] with corresponding layer of pubspec dependencies
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{};
    _dependencies.forEach((e) {
      map[e.name] = e.pubspecValue;
    });
    return map;
  }
}

/// An implemented class of [PackageDependencySetFactory]
class PackageDependencySet extends PackageDependencySetFactory {
  PackageDependencySet({Iterable<PackageDependency>? import}) : super(import);
}

/// An extended class from [PackageDependencySetFactory], but forcing
/// [VersioningPackageDependency] uses exact version
class OverridePackageDependencySet extends PackageDependencySetFactory {
  /// Create new override set
  OverridePackageDependencySet({Iterable<PackageDependency>? import})
      : super(import) {
    trim();
  }

  void _versionChecker(PackageDependency dependency) {
    if (dependency is VersioningPackageDependency) {
      try {
        Version.parse(dependency.version!);
      } on FormatException {
        throw FormatException(
            "Please provide absolute version of the package which using to be override.",
            dependency.version);
      } on NullThrownError {
        throw FormatException(
            "Override package must provide proper version, not null");
      }
    }
  }

  /// Remove all [VersioningPackageDependency] which will caught
  /// [FormatException]
  void trim() => _dependencies.removeWhere((element) {
        try {
          _versionChecker(element);
          return false;
        } on FormatException {
          return true;
        }
      });

  /// Add a package that planning to override
  ///
  /// Throws [FormatException] if [VersioningPackageDependency] provided
  /// non-absolute version of the package
  @override
  bool add(PackageDependency value) {
    _versionChecker(value);
    return super.add(value);
  }

  /// Convert to map data
  ///
  /// And remove all invalid [VersioningPackageDependency] when caught
  /// [FormatException] by calling [trim]
  @override
  Map<String, dynamic> toMap() {
    trim();
    return super.toMap();
  }
}

/// Standarise class for defining package depencies
///
/// It contains package name and other data realted to this [PackageDependency]
/// according import method
abstract class PackageDependency<V> {
  /// Package's name, which is key field in `pubspec.yaml`
  final String name;

  /// Create depencies infos
  PackageDependency(this.name)
      : assert(validator.hasValidatedName(name),
            "$name is not valid package naming.");

  /// Value field of the `pubspec.yaml`
  V get pubspecValue;

  /// Get [hashCode] from [name]
  @override
  int get hashCode => name.hashCode;

  /// To [compare] is the same package name with this object
  bool operator ==(Object? compare) =>
      (compare is PackageDependency) && compare.hashCode == hashCode;
}

/// A mixin with providing version data
mixin VersioningPackageDependency<V> on PackageDependency<V> {
  late String? _version;

  /// Assign new [version] value
  ///
  /// Apply `null` to [newVal] as the same value of `any`
  ///
  /// Throws [AssertionError] if [newVal] has invalid format
  set version(String? newVal) {
    assert(validator.hasValidatedVersioning(newVal ?? "any"),
        "$newVal is not valid versioning string for pub");
    _version = newVal;
  }

  /// Get current assigned [version]
  String? get version => _version;
}

/// A package dependency which get from [pub.dev](https://pub.dev)
class HostedPackageDependency extends PackageDependency<String?>
    with VersioningPackageDependency {
  /// Create new [HostedPackageDependency] information
  HostedPackageDependency({required String name, required String? version})
      : super(name) {
    this.version = version;
  }

  @override
  String? get pubspecValue => version;
}

/// A package dependency which get from third party package hosting site
///
/// If the package is hosting in Git, please use [GitPackageDependency]
class ThirdPartyHostedPackageDependency
    extends PackageDependency<Map<String, dynamic>>
    with VersioningPackageDependency {
  late String _hostedPackageName, _hostedUrl;

  /// Assign hosted package name with [newVal]
  ///
  /// Throws [AssertionError] if [newVal] does not meet requirement of package
  /// naming
  set hostedPackageName(String newVal) {
    assert(
        validator.hasValidatedName(newVal), "$newVal is invalid package name");
    _hostedPackageName = newVal;
  }

  /// Assign hosted URL with [newVal]
  ///
  /// Throws [AssertionError] if [newVal] format is invalid
  set hostedUrl(String newVal) {
    assert(validator.hasValidateHttpFormat(newVal),
        "$newVal is not valid URL of package hosting site");
    _hostedUrl = newVal;
  }

  /// Get name of hosted package
  String get hostedPackageName => _hostedPackageName;

  /// Get hosted URL
  String get hostedUrl => _hostedUrl;

  /// Create new [ThirdPartyHostedPackageDependency] information
  ThirdPartyHostedPackageDependency(
      {required String name,
      required String? version,
      required String hostedPackageName,
      required String hostedUrl})
      : super(name) {
    this.version = version;
    this.hostedPackageName = hostedPackageName;
    this.hostedUrl = hostedUrl;
  }

  @override
  Map<String, dynamic> get pubspecValue => {
        "hosted": {"name": hostedPackageName, "url": hostedUrl},
        "version": version
      };
}

/// A package can be found in local computer
class LocalPackageDependency extends PackageDependency<Map<String, String>> {
  /// Path to package
  String packagePath;

  /// Get package dependency information of [LocalPackageDependency]
  LocalPackageDependency({required String name, required this.packagePath})
      : super(name);

  @override
  Map<String, String> get pubspecValue => {"path": packagePath};
}

/// A package from Git
///
/// It refer to getting Dart/Flutter package from Git.
class GitPackageDependency extends PackageDependency<Map<String, dynamic>> {
  late String _gitUrl;

  /// URL of the Git
  ///
  /// It can be either git, ssh or http URL. Otherwise, throws [AssertionError]
  set gitUrl(String newVal) {
    assert(validator.hasValidateGitUri(newVal), "$newVal is not valid Git URL");
    _gitUrl = newVal;
  }

  /// Get Git URL
  String get gitUrl => _gitUrl;

  /// Reference for getting package
  ///
  /// It can be either branch name, tag name or commit hashing
  ///
  /// Leave `null` if won't apply
  String? gitRef;

  /// Relative path of package in Git repository
  ///
  /// Leave `null` if get package from root
  String? gitPath;

  /// Assign new package dependency of [GitPackageDependency]
  GitPackageDependency(
      {required String name, required String gitUrl, this.gitPath, this.gitRef})
      : super(name) {
    this.gitUrl = gitUrl;
  }

  @override
  Map<String, dynamic> get pubspecValue {
    final Map<String, dynamic> map = {
      "git": (gitRef == null && gitPath == null) ? gitUrl : {"url": gitUrl}
    };
    if (gitPath != null) {
      map["git"]!["path"] = gitPath;
    }
    if (gitRef != null) {
      map["git"]!["ref"] = gitRef;
    }
    return map;
  }
}

/// A package that come with SDK
///
/// For example: Flutter
class SDKPackageDependency extends PackageDependency<Map<String, dynamic>>
    with VersioningPackageDependency {
  final bool _lockModifySDK;

  String _sdk;

  /// Define new [sdk] name
  ///
  /// Throws [UnsupportedError] if disallow modification
  set sdk(String newVal) {
    if (_lockModifySDK) {
      throw UnsupportedError("SDK modification is locked");
    } else {
      _sdk = newVal;
    }
  }

  /// Get [sdk] name
  String get sdk => _sdk;

  /// Create new information of [SDKPackageDependency]
  ///
  /// You can set [disallowModifySDK] to `true` to prevent modify SDK name
  SDKPackageDependency(
      {required String name,
      String? version,
      required String sdk,
      bool disallowModifySDK = false})
      : _sdk = sdk,
        _lockModifySDK = disallowModifySDK,
        super(name) {
    this.version = version;
  }

  /// Create new information of Flutter [SDKPackageDependency]
  ///
  /// Creating via [SDKPackageDependency.flutter] disallow editing SDK
  /// target and throws [UnsupportedError] instead
  SDKPackageDependency.flutter({required String name, String? version})
      : _lockModifySDK = true,
        _sdk = "flutter",
        super(name) {
    this.version = version;
  }

  @override
  Map<String, dynamic> get pubspecValue {
    final Map<String, dynamic> map = {"sdk": sdk};
    if (version != null) {
      map["version"] = version;
    }
    return map;
  }
}
