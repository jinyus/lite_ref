// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

part of 'scoped.dart';

/// The function used to create an instance of [T].
typedef CtxCreateFn<T> = T Function(BuildContext);

/// The function called when the [ScopedRef] is disposed.
typedef DisposeFn<T> = void Function(T);

/// A [ScopedRef] is a reference that needs a context to access the instance.
class ScopedRef<T> {
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

  ScopedRef._(
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
  final bool autoDispose;

  final DisposeFn<T>? _onDispose;

  T? _instance;

  int _watchCount = 0;

  /// The number of widgets that have access to the instance.
  int get watchCount => _watchCount;

  final CtxCreateFn<T> _create;

  void _init(BuildContext context) {
    _instance = _create(context);
  }

  /// Returns `true` if this [ScopedRef] is iniitalized
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
  /// If [listen] is `false`, theinstance will not be disposed when the widget
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

    void autoDisposeIfNeeded(ScopedRef<dynamic> ref) {
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
      refOverride._init(context);
      element._cache[_id] = refOverride;
      autoDisposeIfNeeded(refOverride);
      return refOverride._instance as T;
    }

    autoDisposeIfNeeded(this);

    _init(context);

    element._cache[_id] = this;

    return _instance as T;
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
  /// Set [autoDispose] to `false` if you're overridding with an existing
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

  void _dispose() {
    if (_instance == null) return;
    _onDispose?.call(_instance as T);
    if (autoDispose && _onDispose == null) {
      if (_instance case final Disposable d) {
        d.dispose();
      } else if (_instance case final ChangeNotifier c) {
        // covers ChangeNotifier and ValueNotifier
        c.dispose();
      }
    }
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
