part of 'scoped.dart';

/// A [ScopedFamilyRef] is a reference that needs a context to access instances.
@immutable
class ScopedFamilyRef<T, F> implements IScopedRef<T> {
  ///  Creates a new [ScopedFamilyRef] which always return new instances.
  /// If [autoDispose] is set to `true`, a instance will be disposed when
  /// all the widgets that have access to instance are unmounted.
  ///
  /// A [dispose] function does not have to be provided if [T] implements
  /// [Disposable].
  ScopedFamilyRef(
    CtxFamilyCreateFn<T, F> create, {
    DisposeFn<T>? dispose,
    this.autoDispose = true,
  })  : _create = create,
        _onDispose = dispose,
        _id = Object();

  const ScopedFamilyRef._(
    CtxFamilyCreateFn<T, F> create,
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

  final CtxFamilyCreateFn<T, F> _create;

  ScopedObject<T> _createRefObject(BuildContext context, F family) {
    final refObject = ScopedObject<T>(
      id: (_id, family),
      dispose: _onDispose,
      instance: _create(context, family),
      autoDispose: autoDispose,
    );
    return refObject;
  }

  /// Returns `true` if this [ScopedFamilyRef] with that [family] is initialized
  /// in the current [LiteRefScope].
  bool exists(BuildContext context, F family) {
    assert(
      context is Element,
      'This must be called with the context of a Widget.',
    );

    final element = LiteRefScope._of(context, this);

    return element._cache.containsKey((_id, family));
  }

  /// Returns the instance of [T] in the current scope for that family.
  ///
  /// If [listen] is `false`, the instance will not be disposed when the widget
  /// is unmounted.
  ///
  /// ```dart
  /// class ProductWidget extends StatelessWidget {
  ///   const SettingsPage({required this.id, super.key});
  ///
  ///   final int id;
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final productController = productControllerRef.of(context, id);
  ///     return Text(productController.getName());
  ///   }
  /// }
  /// ```

  T of(BuildContext context, F family, {bool listen = true}) {
    assert(
      context is Element,
      'This must be called with the context of a Widget.',
    );

    final element = LiteRefScope._of(context, this);

    final existing = element._cache[(_id, family)];

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
          (refOverride as ScopedFamilyRef)._createRefObject(context, family);
      element._cache[refObject._id] = refObject;
      autoDisposeIfNeeded(refObject);
      return refObject._instance as T;
    }

    final refObject = _createRefObject(context, family);

    autoDisposeIfNeeded(refObject);

    element._cache[refObject._id] = refObject;

    return refObject._instance;
  }

  /// Returns the instance of [T] in the current scope without disposing it
  /// when the widget is unmounted. This should be used in callbacks like
  /// `onPressed` or `onTap`.
  ///
  /// Alias for `of(context, family, listen: false)`.
  T read(BuildContext context, F family) {
    return of(context, family, listen: false);
  }

  /// Equivalent to calling the [of(context, family)] getter.
  T call(BuildContext context, F family) => of(context, family);

  /// Returns a new ScopedFamilyRef with a different [create] function.
  /// When used with a [LiteRefScope] overrides, any child widget that accesses
  /// the instance will use the new [create] function.
  ///
  /// Set [autoDispose] to `false` if you're overriding with an existing
  /// instance and you don't want the instance to be disposed
  /// when all the widgets that have access to it are unmounted.
  ///```dart
  ///LiteRefScope(
  ///    overrides: [
  ///       productServiceRef.overrideWith((ctx, _) => MockProductService()),
  ///    ]
  ///    child: MyApp(),
  ///    ),
  ///```
  ScopedFamilyRef<T, F> overrideWith(
    CtxFamilyCreateFn<T, F> create, {
    bool autoDispose = true,
  }) {
    return ScopedFamilyRef._(
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
    if (other is ScopedFamilyRef<T, F>) return _id == other._id;
    return false;
  }

  @override
  int get hashCode => _id.hashCode;
}
