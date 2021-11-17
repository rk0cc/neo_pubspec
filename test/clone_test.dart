import 'package:neo_pubspec/src/structre/structre.dart';
import 'package:test/test.dart';

void main() {
  test("Perform deep clone", () {
    var origin = HostedPackageDependency(name: "foo", version: "^1.0.0");
    var cloned = origin.clone;

    expect(origin.version, equals(cloned.version));
    expect(origin.hashCode, isNot(equals(cloned)));
  });
}
