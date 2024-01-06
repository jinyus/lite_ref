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

    _instance = await _create!();

    _success = true;

    return _instance as T;
  }

  /// A shorthand for getting the value of the [LiteAsyncRef].
  /// It's equivalent to calling the [instance] getter.
  Future<T> call() async => instance;

  /// Overrides the value of the current [LiteAsyncRef]
  /// with the provided [create].
  @visibleForTesting
  Future<void> overrideWith(Future<T> Function() create) async {
    _create = create;
    if (_cache && _success) {
      _instance = await _create!();
    }
  }
}
