import '../validator.dart' as validator;

/// Standarise class for defining package depencies
abstract class PackageDependency {
  /// Package's name, which is key field in `pubspec.yaml`
  final String name;

  /// Create depencies infos
  PackageDependency(this.name)
      : assert(validator.hasValidatedName(name),
            "$name is not valid package naming.");

  /// Value field of the `pubspec.yaml`
  dynamic get pubspecValue;
}
