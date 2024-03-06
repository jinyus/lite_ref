part of 'async.dart';

/// A [AsyncSingletonRef] is a reference with an asynchronous factory/creation
/// function that always return the same instance.
class AsyncSingletonRef<T> extends AsyncTransientRef<T> {
  /// {@macro ref}
  AsyncSingletonRef(super.create);

  T? _instance;
  var _success = false;
  Completer<Object?>? _lock;

  /// Returns `true` if the instance has been created.
  bool get hasInstance => _success;

  /// Returns instance if it has been created.
  /// Otherwise, it throws a [StateError].
  T get assertInstance {
    if (hasInstance) return _instance as T;

    throw StateError(
      'The instance has not been created yet. '
      'You must call `instance` first and await it.',
    );
  }

  /// Returns a the singleton instance of [T].
  @override
  Future<T> get instance async {
    // only return the instance if it was successfully created
    if (_success) return _instance as T;

    // if the instance is being created, wait for it to finish
    if (_lock != null) {
      final result = await _lock!.future;

      if (result == null) return _instance as T;

      // attempt to create the instance again if it failed
    }

    // create the instance and return it
    _lock = Completer<Object?>();

    try {
      _instance = await _create();

      _success = true;

      _lock!.complete(null);
      _lock = null;
      return _instance as T;
    } catch (e) {
      _lock?.complete(e);
      _lock = null;
      rethrow;
    }
  }

  /// Sets the function used to create instances.
  /// Throws a [StateError] if `this` has been frozen.
  @override
  @visibleForTesting
  Future<void> overrideWith(AsyncFactory<T> create) async {
    _assertNotFrozen();

    _create = create;

    if (_success) {
      _success = false;
      _instance = await _create();
      _success = true;
    }
  }
}
