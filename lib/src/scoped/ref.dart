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

  /// Returns the instance of [T] in the current scope.
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
  /// When used with a [LiteRefScope] overrides, any child widget that accesses
  /// the instance will use the new [create] function.
  ///```dart
  ///LiteRefScope(
  ///    overrides: [
  ///       settingsServiceRef.overrideWith((ctx) => MockSettingsService()),
  ///    ]
  ///    child: MyApp(),
  ///    ),
  ///```
  ScopedRef<T> overrideWith(CtxCreateFn<T> create) {
    return ScopedRef._(create, _id, dispose: _onDispose);
  }

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
