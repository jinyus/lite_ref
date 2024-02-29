import 'package:lite_ref/src/async/async.dart';
import 'package:lite_ref/src/scoped/scoped.dart';
import 'package:lite_ref/src/sync/sync.dart';

/// {@macro ref}
abstract class Ref {
  /// Creates a new [ScopedRef] which requires a context to access the instance.
  static ScopedRef<T> scoped<T>(
    CtxCreateFn<T> create, {
    DisposeFn<T>? dispose,
  }) {
    return ScopedRef<T>(create, dispose: dispose);
  }

  /// Creates a new [SingletonRef] which always return the same instance.
  static SingletonRef<T> singleton<T>(T Function() create) {
    return SingletonRef<T>(create);
  }

  /// Creates a new [TransientRef] which always return a new instance.
  static TransientRef<T> transient<T>(T Function() create) {
    return TransientRef<T>(create);
  }

  /// Creates a new [AsyncSingletonRef] which always return the same instance.
  static AsyncSingletonRef<T> asyncSingleton<T>(
    Future<T> Function() create,
  ) {
    return AsyncSingletonRef<T>(create);
  }

  /// Creates a new [AsyncTransientRef] which always return a new instance.
  static AsyncTransientRef<T> asyncTransient<T>(
    Future<T> Function() create,
  ) {
    return AsyncTransientRef<T>(create);
  }
}
