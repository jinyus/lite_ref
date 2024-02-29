## 0.4.0

-   [Breaking] This now a flutter package
-   Add `ScopedRef` which is a ref that needs a context to access its instance
-   Add `LiteRefScope` which coupled with`ScopedRef` is an alternative to `Provider` for classes that don't rebuild widgets.

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
            overrides: [
                settingsServiceRef.overrideWith((ctx) => MockSettingsService()),
            ]
            child: MyApp(),
            ),
        ```

## 0.3.0

-   Make the factory function non-nullable (improves performance and maintainability)

## 0.2.1

-   Internal performance improvements
-   fix minor bug where async singleton would not be replace when overridden

## 0.2.0

-   separate singleton and transient instantiation use: `Ref.singleton`, `Ref.transient`, `Ref.asyncSingleton` and `Ref.asyncTransient`
-   add `assertInstance` getter for synchronous access to a AsyncSingletonRef

## 0.1.0

-   prevent race condition when fetching async singleton
-   add `assertInstance` getter for synchronous access to a LiteAsyncRef
-   add `.freeze()` method which disables overriding

## 0.0.2

-   Update readme

## 0.0.1

-   Initial release
