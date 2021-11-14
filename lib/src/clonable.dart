/// Indicate this [Object] can be cloned with same value but different memory
/// location object
///
/// Please keep this mixin not public
mixin Clonable {
  /// Generate new [Object] with delicated memory location
  ///
  /// This allows to perform
  /// [Memento Pattern](https://en.wikipedia.org/wiki/Memento_pattern) that the
  /// variable will not shared the same location which allowing save difference
  /// when doing changed.
  Object get clone;
}
