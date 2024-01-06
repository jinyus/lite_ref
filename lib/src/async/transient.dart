part of 'async.dart';

/// A function that creates an instance of [T] asynchronousloy.
typedef AsyncFactory<T> = Future<T> Function();

/// A [AsyncTransientRef] is a reference with an asynchronous
/// factory/creation function that always return a new instance.
class AsyncTransientRef<T> {
  /// {@macro ref}
  AsyncTransientRef({AsyncFactory<T>? create}) : _create = create;

  AsyncFactory<T>? _create;

  var _frozen = false;

  void _assertCreate() {
    if (_create == null) {
      throw StateError(
        'The creation function is not defined. '
        'Did you forget to call `overrideWith`?',
      );
    }
  }

  void _assertNotFrozen() {
    if (_frozen || Ref.allFrozen) {
      throw StateError(
        'This Ref has been frozen and cannot be overridden.',
      );
    }
  }

  /// Returns a new instance of [T].
  Future<T> get instance {
    _assertCreate();
    return _create!();
  }

  /// Equivalent to calling the [instance] getter.
  Future<T> call() => instance;

  /// Sets the function used to create instances.
  /// Throws a [StateError] if `this` has been frozen.
  @visibleForTesting
  void overrideWith(AsyncFactory<T> create) {
    _assertNotFrozen();
    _create = create;
  }

  /// Disables overriding of the creation function.
  void freeze() {
    _frozen = true;
  }
}
