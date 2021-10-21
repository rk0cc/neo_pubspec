import 'package:pub_semver/pub_semver.dart';

final RegExp _httpScheme = RegExp(r"^https?$");

/// Check [name] is meet requirment of pubspec naming
bool hasValidatedName(String name) =>
    RegExp(r"^[a-z0-9_]$").hasMatch(name) &&
    <String>{
      "assert",
      "break",
      "case",
      "catch",
      "class",
      "const",
      "continue",
      "default",
      "do",
      "else",
      "enum",
      "extends",
      "false",
      "final",
      "finally",
      "for",
      "if",
      "in",
      "is",
      "new",
      "null",
      "rethrow",
      "return",
      "super",
      "switch",
      "this",
      "throw",
      "true",
      "try",
      "var",
      "void",
      "while",
      "with"
    }.where((reservedkw) => reservedkw == name).isEmpty;

/// Check the [description] is has enough charather
///
/// Set [privatePackage] to `true` if not going to publish
bool hasEnoughLengthDescription(String description,
        {bool privatePackage = false}) =>
    privatePackage
        ? true
        : (description.length >= 60 && description.length <= 180);

/// Check this [version] string is a valid format from
///
/// Set [dependency] to `false` if uses for checking owner package's versioning
bool hasValidatedVersioning(String version, {bool dependency = true}) {
  try {
    dependency ? VersionConstraint.parse(version) : Version.parse(version);
    return true;
  } on FormatException {
    return false;
  }
}

/// Check [site] is a valid HTTP or HTTPS format
bool hasValidateHttpFormat(String site) {
  try {
    Uri uri = Uri.parse(site);
    return _httpScheme.hasMatch(uri.scheme);
  } on FormatException {
    return false;
  }
}

/// Check [site] is valid Git URL
bool hasValidateGitUri(String site) {
  try {
    Uri uri = Uri.parse(site);
    return _httpScheme.hasMatch(uri.scheme) &&
        RegExp(r".git$").hasMatch(uri.path);
  } on FormatException {
    return RegExp(r"^(git|ssh)@\w+\.\w+:.+\.git$", dotAll: true).hasMatch(site);
  }
}
