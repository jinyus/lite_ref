<p align="center">
  <img width="500" src="https://github.com/jinyus/lite_ref/blob/main/assets/logo.jpg?raw=true">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-purple"> 
  <a href="https://app.codecov.io/github/jinyus/lite_ref"><img src="https://img.shields.io/codecov/c/github/jinyus/lite_ref"></a>
  <a href="https://pub.dev/packages/lite_ref"><img src="https://img.shields.io/pub/points/lite_ref?color=blue"></a>
</p>

## Overview

Lite Ref is a lightweight dependency injection library for Dart and Flutter.

## Why Lite Ref?

-   **Fast**: Lite Ref doesn't use hashmaps to store instances so it's faster than _all_ other DI libraries.
-   **Safe**: Lite Ref uses top level variables so it's impossible to get a NOT_FOUND error.
-   **Lightweight**: Lite Ref has no dependencies.
-   **Simple**: Lite Ref is simple to use and has a small API surface:

    -   Create a singleton:

        ```dart
        final dbRef = LiteRef(create: () => Database());
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
        dbRef.freeze();
        ```

    -   Create a transient instance (always return new instance):

        ```dart
        final dbRef = LiteRef(create: () => Database(), cache: false);
        assert(dbRef.instance != dbRef.instance);
        ```

    -   Create a singleton asynchronously:

        ```dart
        final dbRef = LiteAsyncRef(create: () async => await Database.init());
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

## Installation

```bash
dart pub add lite_ref
```

## Usage

LifeRefs are lazy. They are only instantiated when you call `instance` or `()`.

```dart
import 'package:lite_ref/lite_ref.dart';


// create a singleton
final dbRef = LiteRef(create: () => Database('example-connection-string'));

// use it
// refs are also callable so you can replace dbRef.instance with dbRef()
final db = dbRef.instance;

// override for testing
dbRef.overrideWith(() => MockDatabase());

// create a transient (always new instance) by setting cache to false
final userServiceRef = LiteRef(
    create: () => UserService(database: db),
    cache: false,
  );
```
