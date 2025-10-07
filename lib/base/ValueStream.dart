import 'dart:async';

/// A Stream wrapper that caches the last emitted value
class ValueStream<T> {
  final StreamController<T> _controller;
  T? _lastValue;
  bool _hasValue = false;

  ValueStream({bool broadcast = true})
      : _controller = broadcast
      ? StreamController<T>.broadcast()
      : StreamController<T>();

  /// Get the stream
  Stream<T> get stream async* {
    // Yield last value immediately if exists
    if (_hasValue) {
      yield _lastValue as T;
    }
    yield* _controller.stream;
  }

  /// Get the last emitted value (nullable)
  T? get value => _lastValue;

  /// Get the last emitted value or throw if no value exists
  T get valueOrThrow {
    if (!_hasValue) {
      throw StateError('No value has been emitted yet');
    }
    return _lastValue as T;
  }

  /// Check if a value has been emitted
  bool get hasValue => _hasValue;

  /// Add a new value to the stream
  void add(T value) {
    _lastValue = value;
    _hasValue = true;
    _controller.add(value);
  }

  /// Add an error to the stream
  void addError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  /// Check if the stream is closed
  bool get isClosed => _controller.isClosed;

  /// Close the stream
  Future<void> close() => _controller.close();

  /// Clear the cached value
  void clearValue() {
    _lastValue = null;
    _hasValue = false;
  }
}

/// Extension method to convert any Stream to ValueStream
extension StreamToValueStream<T> on Stream<T> {
  /// Convert this stream to a ValueStream
  ValueStream<T> toValueStream() {
    final valueStream = ValueStream<T>();
    listen(
          (data) => valueStream.add(data),
      onError: (error, stackTrace) => valueStream.addError(error, stackTrace),
      onDone: () => valueStream.close(),
    );
    return valueStream;
  }
}