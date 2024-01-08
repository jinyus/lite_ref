part of 'sync.dart';

/// A [SingletonRef] is a reference that always returns a new instance.
class SingletonRef<T> extends TransientRef<T> {
  /// {@macro ref}
  SingletonRef(super.create);

  late T _instance = _create();
  var _called = false;

  /// Returns the singleton instance of [T].
  @override
  T get instance {
    if (_called) return _instance;

    _called = true;

    return _instance;
  }

  /// Sets the function used to create instances.
  /// Throws a [StateError] if `this` has been frozen.
  @override
  @visibleForTesting
  void overrideWith(T Function() create) {
    _assertNotFrozen();

    _create = create;

    if (_called) {
      _instance = _create();
    }
  }
}
