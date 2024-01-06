import 'package:meta/meta.dart';

/// A [LiteRef] is a reference to a value that can be overridden.
class LiteRef<T> {
  /// {@macro ref}
  LiteRef({T Function()? create, bool cache = true})
      : _cache = cache,
        _create = create;

  T Function()? _create;
  final bool _cache;
  late T _instance = _create!();
  var _called = false;

  /// Returns the value of the [LiteRef]. If caching is enabled,
  /// it will return the cached value.
  /// Otherwise, it will call the create function to generate a new value.
  T get instance {
    if (_create == null) {
      throw StateError(
        'The creation function is not defined. '
        'Did you forget to call `overrideWith`?',
      );
    }
    _called = true;
    return _cache ? _instance : _create!();
  }

  /// A shorthand for getting the value of the [LiteRef].
  /// It's equivalent to calling the [instance] getter.
  T call() => instance;

  /// Overrides the value of the current [LiteRef]
  /// with the provided [create].
  @visibleForTesting
  void overrideWith(T Function() create) {
    _create = create;
    if (_cache && _called) {
      _instance = _create!();
    }
  }
}
