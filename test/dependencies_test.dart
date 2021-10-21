import 'package:neo_pubspec/src/structre/structre.dart' hide PubspecInfo;
import 'package:test/test.dart';

void main() {
  group("Import mock test", () {
    Map<String, dynamic> dummy = {
      "flutter": {"sdk": "flutter"},
      "foo_pkg": "^1.0.0",
      "foo_bar": "^1.3.0",
      "foo_git": {
        "git": {"url": "https://example.com/sample/foo.git", "path": "foo_pkg/"}
      },
      "foo_git_nd": {"git": "https://example.com/sample/foo_nd.git"},
      "local_foo": {"path": "../foo"},
      "alien": {
        "hosted": {"url": "https://example.com", "name": "alien"},
        "version": "^9.5.2"
      }
    };
    PackageDependencySet pkgSet =
        PackageDependencySet.fromMap<Map<String, dynamic>>(dummy);
    test("validate package set", () {
      expect(pkgSet.length, equals(dummy.length));
      expect(pkgSet.toMap(), equals(dummy));
    });
    test("SDK package info", () {
      expect(pkgSet.lookup("flutter"),
          equals(SDKPackageDependency.flutter(name: "flutter")));
    });
    test("Git package", () {
      expect((pkgSet.lookup("foo_git_nd") as GitPackageDependency).gitUrl,
          equals("https://example.com/sample/foo_nd.git"));
      expect((pkgSet.lookup("foo_git") as GitPackageDependency).gitUrl,
          equals("https://example.com/sample/foo.git"));
    });
    test("local package", () {
      expect((pkgSet.lookup("local_foo") as LocalPackageDependency).packagePath,
          equals("../foo"));
    });
    test("hosted package", () {
      expect(
          pkgSet.where((element) => element is HostedPackageDependency).length,
          equals(2));
      expect(
          pkgSet
              .where((element) =>
                  element is VersioningPackageDependency &&
                  element is! SDKPackageDependency)
              .length,
          equals(3));
      expect(
          (pkgSet.lookup("alien") as ThirdPartyHostedPackageDependency).version,
          equals("^9.5.2"));
    });
  });
  group("Invalid import", () {
    test("disallow more than one import method", () {
      expect(
          () => PackageDependencySet.fromMap<Map<String, dynamic>>({
                "chao_pkg": {
                  "git": "https://www.example.com/sample/lol.git",
                  "path": "../lol"
                }
              }),
          throwsA(isA<FormatException>()));
    });
    test("use invalid type", () {
      expect(() => PackageDependencySet.fromMap<Map<int, dynamic>>({1: "Ha"}),
          throwsA(isA<TypeError>()));
    });
    test("no versioning in Git and local package import", () {
      expect(
          () => PackageDependencySet.fromMap<Map<String, dynamic>>({
                "chao_pkg": {
                  "git": "https://www.example.com/sample/lol.git",
                  "version": "^6.0.0"
                }
              }),
          throwsA(isA<FormatException>()));
      expect(
          () => PackageDependencySet.fromMap<Map<String, dynamic>>({
                "chao_pkg": {"path": "../lol", "version": "^7.0.1"}
              }),
          throwsA(isA<FormatException>()));
    });
  });
}
