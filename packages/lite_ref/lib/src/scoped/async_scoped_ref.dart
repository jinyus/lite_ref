part of 'scoped.dart';

class ScopedAsyncRef<T> implements IScopedRef<T> {
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

  bool exists(BuildContext context) {
    assert(
      context is Element,
      'This must be called with the context of a Widget.',
    );

    final element = LiteRefScope._of(context, this);

    return element._cache.containsKey(_id);
  }

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

  Future<T> read(BuildContext context) {
    return of(context, listen: false);
  }

  Future<T> call(BuildContext context) => of(context);

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
