import 'package:lite_ref/src/async/async.dart';
import 'package:lite_ref/src/sync/sync.dart';

var _allFrozen = false;

/// {@macro ref}
abstract class Ref {
  /// Creates a new [SingletonRef] which always return the same instance.
  static SingletonRef<T> singleton<T>({T Function()? create}) {
    return SingletonRef<T>(create: create);
  }

  /// Creates a new [TransientRef] which always return a new instance.
  static TransientRef<T> transient<T>({T Function()? create}) {
    return TransientRef<T>(create: create);
  }

  /// Creates a new [AsyncSingletonRef] which always return the same instance.
  static AsyncSingletonRef<T> asyncSingleton<T>({
    Future<T> Function()? create,
  }) {
    return AsyncSingletonRef<T>(create: create);
  }

  /// Creates a new [AsyncTransientRef] which always return a new instance.
  static AsyncTransientRef<T> asyncTransient<T>({
    Future<T> Function()? create,
  }) {
    return AsyncTransientRef<T>(create: create);
  }

  /// A function that disables overriding for all lite refs.
  /// This is typically done after setting up your dependencies.
  static void freezeAll() {
    _allFrozen = true;
  }

  /// Whether or not all lite refs are frozen.
  static bool get allFrozen => _allFrozen;
}
