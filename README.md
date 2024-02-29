<p align="center">
  <img width="500" src="https://github.com/jinyus/lite_ref/blob/main/assets/lite_ref_banner.jpg?raw=true">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-purple"> 
  <a href="https://app.codecov.io/github/jinyus/lite_ref"><img src="https://img.shields.io/codecov/c/github/jinyus/lite_ref"></a>
  <a href="https://pub.dev/packages/lite_ref"><img src="https://img.shields.io/pub/points/lite_ref?color=blue"></a>
</p>

## Overview

Lite Ref is a lightweight dependency injection library for Dart and Flutter.

## Installation

```bash
dart pub add lite_ref
```

## Why Lite Ref?

-   **Fast**: Doesn't use hashmaps to store instances so it's faster than _all_ other DI libraries.
-   **Safe**: Uses top level variables so it's impossible to get a NOT_FOUND error.
-   **Lightweight**: Has no dependencies.
-   **Simple**: Easy to learn with a small API surface

## Scoped Refs

A `ScopedRef` is a reference that needs a build context to access its instance. This is an alternative to `Provider` for classes that don't rebuild widgets. eg: Controllers, Repositories, Services, etc.

-   Wrap your app with a `LiteRefScope`:

    ```dart
    runApp(
      LiteRefScope(
        child: MyApp(),
      ),
    );
    ```

-   Create a `ScopedRef`.

    ```dart
    final settingsServiceRef = Ref.scoped((ctx) => SettingsService());
    ```

-   Access the instance in the current scope:

    This can be done in a widget by using `settingsServiceRef.of(context)` or `settingsServiceRef(context)`.

    ```dart
    class SettingsPage extends StatelessWidget {
      const SettingsPage({super.key});

      @override
      Widget build(BuildContext context) {
        final settingsService = settingsServiceRef.of(context);
        return Text(settingsService.getThemeMode());
      }
    }
    ```

-   Override it for a subtree:

    You can override the instance for a subtree by using `overrideWith`. This is useful for testing.
    In the example below all calls to `settingsServiceRef.of(context)` will return `MockSettingsService`.

    ```dart
    LiteRefScope(
        overrides: [
            settingsServiceRef.overrideWith((ctx) => MockSettingsService()),
        ]
        child: MyApp(),
        ),
    ```

### Click [here](https://github.com/jinyus/lite_ref/tree/main/example/flutter_example) for a flutter example with testing.

## Global Singletons and Transients

-   Create a singleton:

    ```dart
    final dbRef = Ref.singleton(() => Database());

    assert(dbRef.instance == dbRef.instance);
    ```

-   Use it:

    ```dart
    final db = dbRef.instance; // or dbRef()
    ```

-   Override it (for testing):

    ```dart
    dbRef.overrideWith(() => MockDatabase());
    ```

-   Freeze it (disable overriding):

    ```dart
    // overrideWith is marked as @visibleForTesting so this isn't really necessary.
    dbRef.freeze();
    ```

-   Create a transient instance (always return new instance):

    ```dart
    final dbRef = Ref.transient(() => Database());

    assert(dbRef.instance != dbRef.instance);
    ```

-   Create a singleton asynchronously:

    ```dart
    final dbRef = Ref.asyncSingleton(() async => await Database.init());
    ```

-   Use it:

    ```dart
    final db = await dbRef.instance;
    ```

-   Use it synchronously:

    ```dart
    // only use this if you know the instance is already created
    final db = dbRef.assertInstance;
    ```
