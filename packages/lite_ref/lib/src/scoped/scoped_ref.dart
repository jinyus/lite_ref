part of 'scoped.dart';

/// A [ScopedRef] is a reference that needs a context to access the instance.
@immutable
class ScopedRef<T> implements IScopedRef<T> {
  ///  Creates a new [ScopedRef] which always return a new instance.
  /// If [autoDispose] is set to `true`, the instance will be disposed when
  /// all the widgets that have access to the instance are unmounted.
  ///
  /// A [dispose] function does not have to be provided if [T] implements
  /// [Disposable].
  ScopedRef(
    CtxCreateFn<T> create, {
    DisposeFn<T>? dispose,
    this.autoDispose = true,
  })  : _create = create,
        _onDispose = dispose,
        _id = Object();

  const ScopedRef._(
    CtxCreateFn<T> create,
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

  final CtxCreateFn<T> _create;

  ScopedObject<T> _createRefObject(BuildContext context) {
    final refObject = ScopedObject<T>(
      id: _id,
      dispose: _onDispose,
      instance: _create(context),
      autoDispose: autoDispose,
    );
    return refObject;
  }

  /// Returns `true` if this [ScopedRef] is initialized
  /// in the current [LiteRefScope].
  bool exists(BuildContext context) {
    assert(
      context is Element,
      'This must be called with the context of a Widget.',
    );

    final element = LiteRefScope._of(context, this);

    return element._cache.containsKey(_id);
  }

  /// Returns the instance of [T] in the current scope.
  ///
  /// If [listen] is `false`, the instance will not be disposed when the widget
  /// is unmounted.
  ///
  /// ```dart
  /// class SettingsPage extends StatelessWidget {
  ///   const SettingsPage({super.key});
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final settingsService = settingsServiceRef.of(context);
  ///     return Text(settingsService.getThemeMode());
  ///   }
  /// }
  /// ```
  T of(BuildContext context, {bool listen = true}) {
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
      final refObject = (refOverride as ScopedRef)._createRefObject(context);
      element._cache[refObject._id] = refObject;
      autoDisposeIfNeeded(refObject);
      return refObject._instance as T;
    }

    final refObject = _createRefObject(context);

    autoDisposeIfNeeded(refObject);

    element._cache[refObject._id] = refObject;

    return refObject._instance;
  }

  /// Returns the instance of [T] in the current scope without disposing it
  /// when the widget is unmounted. This should be used in callbacks like
  /// `onPressed` or `onTap`.
  ///
  /// Alias for `of(context, listen: false)`.
  T read(BuildContext context) {
    return of(context, listen: false);
  }

  /// Equivalent to calling the [of(context)] getter.
  T call(BuildContext context) => of(context);

  /// Returns a new ScopedRef with a different [create] function.
  /// When used with a [LiteRefScope] overrides, any child widget that accesses
  /// the instance will use the new [create] function.
  ///
  /// Set [autoDispose] to `false` if you're overriding with an existing
  /// instance and you don't want the instance to be disposed
  /// when all the widgets that have access to it are unmounted.
  ///```dart
  ///LiteRefScope(
  ///    overrides: [
  ///       settingsServiceRef.overrideWith((ctx) => MockSettingsService()),
  ///    ]
  ///    child: MyApp(),
  ///    ),
  ///```
  ScopedRef<T> overrideWith(CtxCreateFn<T> create, {bool autoDispose = true}) {
    return ScopedRef._(
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
    if (other is ScopedRef<T>) return _id == other._id;
    return false;
  }

  @override
  int get hashCode => _id.hashCode;
}
