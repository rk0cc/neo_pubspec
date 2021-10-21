import 'package:neo_pubspec/src/validator.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

main() {
  group("Validation test", () {
    test("git site", () {
      expect(hasValidateGitUri("git@example.com:foo/bar.git"), equals(true));
      expect(hasValidateGitUri("https://www.example.com/foo/bar.git"),
          equals(true));
      expect(hasValidateGitUri("ftp://ftp.example.com/foo/bar.git"),
          equals(false));
    });
  });
}
