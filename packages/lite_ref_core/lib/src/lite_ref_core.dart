// ignore_for_file: lines_longer_than_80_chars

import 'package:lite_ref_core/src/async/async.dart';
import 'package:lite_ref_core/src/sync/sync.dart';

/// abstract class for creating refs.
/// ```dart
/// final singleton = Ref.singleton(() => Database());
/// final transient = Ref.transient(() => APIClient());
/// ```
abstract class Ref {
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
