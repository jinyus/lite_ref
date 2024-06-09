// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

part of 'scoped.dart';

/// Used for creating and retrieving an asynchronously created object.
class ScopedAsyncRef<T> implements IScopedRef<T> {

  /// Creates a new [ScopedAsyncRef] which always return a new instance.
  /// If [autoDispose] is set to `true`, the instance will be disposed when
  /// all the widgets that have access to the instance are unmounted.
  ///
  /// A [dispose] function does not have to be provided if [T] implements
  /// [Disposable].
  ScopedAsyncRef(
    CtxCreateAsyncFn<T> create, {
    DisposeFn<T>? dispose,
    this.autoDispose = true,
  })  : _create = create,
        _onDispose = dispose,
        _id = Object();

  ScopedAsyncRef._(
    CtxCreateAsyncFn<T> create,
    Object id, {
    required this.autoDispose,
    DisposeFn<T>? dispose,
  })  : _create = create,
        _id = id,
        _onDispose = dispose;

  final Object _id;

  /// Whether the instance should be disposed when all the widgets that have
  /// access to the instance are unmounted.
  @override
  final bool autoDispose;

  final DisposeFn<T>? _onDispose;

  final CtxCreateAsyncFn<T> _create;

  Completer<ScopedObject<T>>? _lock;

  Future<ScopedObject<T>> _createRefObject(BuildContext context) async {
    final ScopedObject<T> result;
    switch (_lock) {
      case null:
        _lock = Completer();
        result = await _create(context).then((value) {
          return ScopedObject<T>(
            id: _id,
            dispose: _onDispose,
            instance: value,
            autoDispose: autoDispose,
          );
        });
        _lock!.complete(result);
      case Completer():
        result = await _lock!.future;
    }
    return result;
  }

  /// Returns `true` if this [ScopedAsyncRef] is initialized
  /// in the current [LiteRefScope].
  bool exists(BuildContext context) {
    assert(
      context is Element,
      'This must be called with the context of a Widget.',
    );

    final element = LiteRefScope._of(context, this);

    return element._cache.containsKey(_id);
  }

  /// Returns the Future of [T] in the current scope.
  ///
  /// If [listen] is `false`, the instance will not be disposed when the widget
  /// is unmounted.
  Future<T> of(BuildContext context, {bool listen = true}) async {
    assert(
      context is Element,
      'This must be called with the context of a Widget.',
    );

    final element = LiteRefScope._of(context, this);

    final existing = element._cache[_id];

    void autoDisposeIfNeeded(ScopedObject<dynamic> ref) {
      if (autoDispose && listen) {
        element._addAutoDisposeBinding(context as Element, ref);
      }
    }

    if (existing != null) {
      autoDisposeIfNeeded(existing);
      return existing._instance as T;
    }

    final refOverride = element.scope.overrides?.lookup(this);

    if (refOverride != null) {
      final refObject =
          await (refOverride as ScopedAsyncRef)._createRefObject(context);
      element._cache[refObject._id] = refObject;
      autoDisposeIfNeeded(refObject);
      return refObject._instance as T;
    }

    final refObject = await _createRefObject(context);

    autoDisposeIfNeeded(refObject);

    element._cache[refObject._id] = refObject;

    return refObject._instance;
  }

  /// Returns the instance of [T] in the current scope.
  ///
  /// If [listen] is `false`, the instance will not be disposed when the widget
  /// is unmounted.
  T assertOf(BuildContext context, {bool listen = true}) {
    assert(
    context is Element,
    'This must be called with the context of a Widget.',
    );

    final element = LiteRefScope._of(context, this);

    final existing = element._cache[_id];

    void autoDisposeIfNeeded(ScopedObject<dynamic> ref) {
      if (autoDispose && listen) {
        element._addAutoDisposeBinding(context as Element, ref);
      }
    }

    if (existing != null) {
      autoDisposeIfNeeded(existing);
      return existing._instance as T;
    }
    throw StateError(
      'The instance has not been created yet. '
          'You must call `instance` first and await it.',
    );
  }

  /// Returns the Future of [T] in the current scope without disposing it
  /// when the widget is unmounted. This should be used in callbacks like
  /// `onPressed` or `onTap`.
  ///
  /// Alias for `of(context, listen: false)`.
  Future<T> read(BuildContext context) {
    return of(context, listen: false);
  }

  /// Returns the Future of [T] in the current scope without disposing it
  /// when the widget is unmounted. This should be used in callbacks like
  Future<T> call(BuildContext context) => of(context);

  /// Returns a new ScopedAsyncRef with a different [create] function.
  /// When used with a [LiteRefScope] overrides, any child widget that accesses
  /// the instance will use the new [create] function.
  ///
  /// Set [autoDispose] to `false` if you're overriding with an existing
  /// instance and you don't want the instance to be disposed
  /// when all the widgets that have access to it are unmounted.
  ScopedAsyncRef<T> overrideWith(
    CtxCreateAsyncFn<T> create, {
    bool autoDispose = true,
  }) {
    return ScopedAsyncRef._(
      create,
      _id,
      dispose: autoDispose ? _onDispose : null,
      autoDispose: autoDispose,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    if (other is ScopedAsyncRef<T>) return _id == other._id;
    return false;
  }

  @override
  int get hashCode => _id.hashCode;
}
