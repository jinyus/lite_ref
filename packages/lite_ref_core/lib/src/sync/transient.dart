part of 'sync.dart';

/// A [TransientRef] is a reference that always return a new instance.
class TransientRef<T> {
  /// {@macro ref}
  TransientRef(T Function() create) : _create = create;

  T Function() _create;

  var _frozen = false;

  void _assertNotFrozen() {
    if (_frozen) {
      throw StateError('This Ref has been frozen and cannot be overridden.');
    }
  }

  /// Returns a new instance of [T].
  T get instance {
    return _create();
  }

  /// Equivalent to calling the [instance] getter.
  T call() => instance;

  /// Sets the function used to create instances.
  /// Throws a [StateError] if `this` has been frozen.
  @visibleForTesting
  void overrideWith(T Function() create) {
    _assertNotFrozen();
    _create = create;
  }

  /// Disables overriding.
  void freeze() {
    _frozen = true;
  }
}
