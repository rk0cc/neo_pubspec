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
}
