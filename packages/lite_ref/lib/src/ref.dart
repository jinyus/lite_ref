// ignore_for_file: lines_longer_than_80_chars

import 'package:lite_ref/src/scoped/scoped.dart';
import 'package:lite_ref_core/lite_ref_core.dart';

/// abstract class for creating refs.
/// ```dart
/// final scoped = Ref.scoped((context) => AuthService());
/// final singleton = Ref.singleton(() => Database());
/// final transient = Ref.transient(() => APIClient());
/// ```
abstract class Ref {
  /// Creates a new [ScopedRef] which requires a context to access the instance.
  ///
  ///  -   Wrap your app or a subtree with a `LiteRefScope`:
  ///
  ///      ```dart
  ///      runApp(
  ///        LiteRefScope(
  ///          child: MyApp(),
  ///        ),
  ///      );
  ///      ```
  ///
  ///  -   Create a `ScopedRef`.
  ///
  ///      ```dart
  ///      final settingsServiceRef = Ref.scoped((ctx) => SettingsService());
  ///      ```
  ///
  ///  -   Access the instance in the current scope:
  ///
  ///      This can be done in a widget by using `settingsServiceRef.of(context)` or `settingsServiceRef(context)`.
  ///
  ///      ```dart
  ///      class SettingsPage extends StatelessWidget {
  ///        const SettingsPage({super.key});
  ///
  ///        @override
  ///        Widget build(BuildContext context) {
  ///          final settingsService = settingsServiceRef.of(context);
  ///          return Text(settingsService.getThemeMode());
  ///        }
  ///      }
  ///      ```
  ///
  ///  -   Override it for a subtree:
  ///
  ///      You can override the instance for a subtree by using `overrideWith`. This is useful for testing.
  ///      In the example below, all calls to `settingsServiceRef.of(context)` will return `MockSettingsService`.
  ///
  ///      ```dart
  ///      LiteRefScope(
  ///          overrides: [
  ///              settingsServiceRef.overrideWith((ctx) => MockSettingsService()),
  ///          ]
  ///          child: MyApp(),
  ///          ),
  ///      ```
  static ScopedRef<T> scoped<T>(
    CtxCreateFn<T> create, {
    DisposeFn<T>? dispose,
    bool autoDispose = true,
  }) {
    return ScopedRef<T>(create, dispose: dispose, autoDispose: autoDispose);
  }

  // coverage:ignore-start
  // tested in lite_ref_core
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
  // coverage:ignore-end
}
