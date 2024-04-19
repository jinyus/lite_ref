part of 'scoped.dart';

/// A [ScopedObject] is a reference that holds an instance of [T].
///
/// If [autoDispose] is set to `true`, the instance will be disposed when
/// all the widgets that have access to the instance are unmounted.
class ScopedObject<T> {
  /// Creates a new [ScopedObject] with an [id] and an [instance].
  ScopedObject({
    required Object id,
    required T instance,
    DisposeFn<T>? dispose,
    this.autoDispose = true,
  })  : _id = id,
        _onDispose = dispose,
        _instance = instance;

  final T _instance;

  final Object _id;

  /// Whether the instance should be disposed when all the widgets that have
  /// access to the instance are unmounted.
  final bool autoDispose;

  final DisposeFn<T>? _onDispose;

  int _watchCount = 0;

  ScopedObject<T> _copy() {
    return ScopedObject(id: _id, instance: _instance);
  }

  void _dispose() {
    if (_instance == null) return;
    _onDispose?.call(_instance);
    if (autoDispose && _onDispose == null) {
      if (_instance case final Disposable d) {
        d.dispose();
      } else if (_instance case final ChangeNotifier c) {
        // covers ChangeNotifier and ValueNotifier
        c.dispose();
      }
    }
  }
}
