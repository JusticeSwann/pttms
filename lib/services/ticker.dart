class Ticker {
  /// Returns a stream that emits an increasing integer every second.
  Stream<int> tick() {
    return Stream.periodic(const Duration(seconds: 1), (x) => x);
  }
}
