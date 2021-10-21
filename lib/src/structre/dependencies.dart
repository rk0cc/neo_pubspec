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

  static PackageDependency importFromMap<M>(M mapData) {
    if (M != Map && M != YamlMap) {
      throw TypeError();
    }

    throw UnimplementedError();
  }

  /// Value field of the `pubspec.yaml`
  V get pubspecValue;

  @override
  int get hashCode => name.hashCode;

  bool operator ==(Object? compare) =>
      (compare is PackageDependency) && compare.hashCode == hashCode;
}

mixin VersioningPackageDependency<V> on PackageDependency<V> {
  late final String? version;
}
