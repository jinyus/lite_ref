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

-   Wrap your app or a subtree with a `LiteRefScope`:

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
    In the example below, all calls to `settingsServiceRef.of(context)` will return `MockSettingsService`.

    ```dart
    LiteRefScope(
      overrides: {
        settingsServiceRef.overrideWith((ctx) => MockSettingsService()),
      },
      child: MyApp(),
    ),
    ```

A `ScopedFamilyRef` is used when you need to create a unique instance for different keys.
This is useful for creating multiple instances of the same class with different configurations.

-   Create a `ScopedFamilyRef`.

    ```dart
    final postControllerRef = Ref.scopedFamily((ctx, String key) {
      return PostController(key)..fetch();
    });
    ```
-   Access the instance in the current scope:

    This can be done in a widget by using `postController.of(context, key)` or `postController(context, key)`.

    ```dart
    class PostsPage extends StatelessWidget {
      const PostsPage({required this.keys, super.key});
    
      final List<String> keys;

      @override
      Widget build(BuildContext context) {
        return ListView.builder(
          itemBuilder: (context, index) {
            final post = postControllerRef.of(context, keys[index]);
            return Text(post?.title ?? 'Loading...');
          },
        );
      }
    }
    ```    

### Disposal

When a `ScopedRef` provides a `ChangeNotifier`, `ValueNotifier` or a class that implements `Disposable`, it will automatically dispose the instance when all the widgets that have access to the instance are unmounted.

In the example below, the `CounterController` will be disposed when the `CounterView` is unmounted.

```dart
class CounterController extends ChangeNotifier {
  var _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }

  void decrement() {
    _count--;
    notifyListeners();
  }
}

final countControllerRef = Ref.scoped((ctx) => CounterController());

class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    final contoller = countControllerRef.of(context);
    return ListenableBuilder(
      listenable: contoller,
      builder: (context, snapshot) {
        return Text('${contoller.count}');
      },
    );
  }
}
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
