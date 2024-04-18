part of 'scoped.dart';

/// The function used to create an instance of [T].
typedef CtxCreateFn<T> = T Function(BuildContext context);

/// The function used to create an instance of [T] with a family [F].
typedef CtxFamilyCreateFn<T, F> = T Function(BuildContext context, F family);

/// The function called when the [IScopedRef] is disposed.
typedef DisposeFn<T> = void Function(T);

/// A [ScopedRef] is a reference that needs a context to access the instance.
sealed class IScopedRef<T> {
  /// Whether the instance should be disposed when all the widgets that have
  /// access to the instance are unmounted.
  bool get autoDispose;
}
