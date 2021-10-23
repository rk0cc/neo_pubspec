import 'package:neo_pubspec/src/validator.dart';
import 'package:random_string/random_string.dart';
import 'package:test/test.dart';

void main() {
  group("Validation test", () {
    test("git site", () {
      expect(hasValidateGitUri("git@example.com:foo/bar.git"), equals(false));
      expect(hasValidateGitUri("git://example.com/foo/bar.git"), equals(true));
      expect(hasValidateGitUri("https://www.example.com/foo/bar.git"),
          equals(true));
      expect(hasValidateGitUri("ftp://ftp.example.com/foo/bar.git"),
          equals(false));
    });
    test("HTTP URL", () {
      expect(hasValidateHttpFormat("ftp://ftp.example.com"), equals(false));
      expect(hasValidateHttpFormat("http://www.foo.com/bar"), equals(true));
      expect(hasValidateHttpFormat("I am URL"), equals(false));
      expect(hasValidateHttpFormat("https://www.example.com"), equals(true));
    });
    group("versioning", () {
      test("package's version", () {
        expect(
            hasValidatedVersioning("1.0.0", dependency: false), equals(true));
        expect(hasValidatedVersioning("1.0.0-alpha-1", dependency: false),
            equals(true));
        expect(
            hasValidatedVersioning("build1", dependency: false), equals(false));
        expect(hasValidatedVersioning("2021-9-1_123456", dependency: false),
            equals(false));
        expect(hasValidatedVersioning("any", dependency: false), equals(false));
        expect(
            hasValidatedVersioning("^1.0.0", dependency: false), equals(false));
      });
      test("dependencies version", () {
        expect(hasValidatedVersioning("1.0.0"), equals(true));
        expect(hasValidatedVersioning("^1.0.0"), equals(true));
        expect(hasValidatedVersioning(">=1.0.0"), equals(true));
        expect(hasValidatedVersioning(">=2.0.0 <1.9.0"), equals(true));
        expect(hasValidatedVersioning("<1.9.0"), equals(true));
        expect(hasValidatedVersioning("any"), equals(true));
      });
    });
    test("description length", () {
      expect(hasEnoughLengthDescription(randomAlpha(5)), equals(false));
      expect(hasEnoughLengthDescription(randomAlpha(78)), equals(true));
      expect(hasEnoughLengthDescription(randomAlpha(181)), equals(false));
    });
    test("package name", () {
      expect(hasValidatedName("Foo"), equals(false));
      expect(hasValidatedName("foo"), equals(true));
      expect(hasValidatedName("async"), equals(true));
      expect(hasValidatedName("while"), equals(false));
    });
  });
}
