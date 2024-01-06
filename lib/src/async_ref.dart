import 'dart:async';
import 'package:meta/meta.dart';

/// A [LiteAsyncRef] is a reference to a value that can be overridden.
class LiteAsyncRef<T> {
  /// {@macro async_ref}
  LiteAsyncRef({Future<T> Function()? create, bool cache = true})
      : _cache = cache,
        _create = create;

  Future<T> Function()? _create;
  final bool _cache;
  T? _instance;
  var _success = false;
  var _frozen = false;
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

  /// Returns the value of the [LiteAsyncRef]. If caching is enabled,
  /// it will return the cached value.
  /// Otherwise, it will call the create function to generate a new value.
  Future<T> get instance async {
    if (_create == null) {
      throw StateError(
        'The creation function is not defined. '
        'Did you forget to call `overrideWith`?',
      );
    }

    if (!_cache) return _create!();

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
      _instance = await _create!();

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

  /// A shorthand for getting the value of the [LiteAsyncRef].
  /// It's equivalent to calling the [instance] getter.
  Future<T> call() async => instance;

  /// Overrides the value of the current [LiteAsyncRef]
  /// with the provided [create].
  /// Throws a [StateError] if `this` has been frozen.
  @visibleForTesting
  Future<void> overrideWith(Future<T> Function() create) async {
    if (_frozen) {
      throw StateError(
        'The value of the LiteRef has been frozen and cannot be overridden.',
      );
    }
    _create = create;
    if (_cache && _success) {
      _instance = await _create!();
    }
  }

  /// Freezes the value of the [LiteAsyncRef].
  /// After freezing, the value of the [LiteAsyncRef] cannot be overridden.
  void freeze() {
    _frozen = true;
  }
}
