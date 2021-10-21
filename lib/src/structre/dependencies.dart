part of 'structre.dart';

/// Providing [SetBase] of [PackageDependency]
///
/// It can be import or export [Map] data
class PackageDependencySet extends SetBase<PackageDependency> {
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

  /// Setup [PackageDependencySet]
  ///
  /// It can [import] existed [Iterable] of [PackageDependency]
  PackageDependencySet({Iterable<PackageDependency>? import}) {
    if (import != null) {
      _dependencies.addAll(import);
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

  @override
  int get hashCode => name.hashCode;

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
  /// Path to package's directory
  late Directory _packagePath;

  /// Apply new package path [Directory]
  ///
  /// Throws [AssertionError] if the path is not exist.
  set packagePath(Directory newVal) {
    assert(newVal.existsSync(), "${newVal.path} is not existed");
    _packagePath = newVal;
  }

  /// Same as [packagePath], but apply [newval] as [String]
  set packagePathString(String newVal) => packagePath = Directory(newVal);

  /// Get package path [Directory] context
  Directory get packagePath => _packagePath;

  /// Return [packagePath.path]
  String get packagePathString => packagePath.path;

  /// Get package dependency information
  ///
  /// Remind that [packagePath] in constructor is [String] which different type
  /// for same name setter which using [Directory].
  ///
  /// If decide to apply [String] [packagePath] after constructor,
  /// please use [packagePathString].
  LocalPackageDependency({required String name, required String packagePath})
      : super(name) {
    this.packagePathString = packagePath;
  }

  @override
  Map<String, String> get pubspecValue => {"path": packagePathString};
}
