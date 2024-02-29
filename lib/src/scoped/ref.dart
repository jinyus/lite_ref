// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

part of 'scoped.dart';

/// The function used to create an instance of [T].
typedef CtxCreateFn<T> = T Function(BuildContext);

/// The function called when the [ScopedRef] is disposed.
typedef DisposeFn<T> = void Function(T);

/// A [ScopedRef] is a reference that needs a context to access the instance.
class ScopedRef<T> {
  ///  Creates a new [ScopedRef] which always return a new instance.
  ScopedRef(CtxCreateFn<T> create, {DisposeFn<T>? dispose})
      : _create = create,
        _onDispose = dispose,
        _id = Object();

  ScopedRef._(CtxCreateFn<T> create, Object id, {DisposeFn<T>? dispose})
      : _create = create,
        _id = id,
        _onDispose = dispose;

  final Object _id;

  DisposeFn<T>? _onDispose;

  T? _instance;

  final CtxCreateFn<T> _create;

  void _init(BuildContext context) {
    _instance = _create(context);
  }

  /// Returns a new instance of [T].
  T of(BuildContext context) {
    final box = LiteRefScope._of(context);

    final existing = box._cache[_id];

    if (existing != null) {
      return existing._instance as T;
    }

    final refOverride = box._overrides?.lookup(this);

    if (refOverride != null) {
      refOverride._init(context);
      box._cache[_id] = refOverride;
      return refOverride._instance as T;
    }

    _init(context);

    box._cache[_id] = this;

    return _instance as T;
  }

  /// Equivalent to calling the [of(context)] getter.
  T call(BuildContext context) => of(context);

  /// Returns a new ScopedRef with a different [create] function.
  /// When used with a [LiteRefScope], any child widget that accesses
  /// the instance will use the new [create] function.
  ScopedRef<T> overrideWith(CtxCreateFn<T> create) {
    return ScopedRef._(create, _id, dispose: _onDispose);
  }

  /// Clears the instance and calls the dispose function if it exists.
  void _dispose() {
    if (_instance == null) return;
    _onDispose?.call(_instance as T);
    _instance = null;
    _onDispose = null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    if (other is ScopedRef<T>) return _id == other._id;
    return false;
  }

  @override
  int get hashCode => _id.hashCode;
}
