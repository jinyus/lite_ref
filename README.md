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

## Installation

```bash
dart pub add lite_ref
```

## Usage

LifeRefs are lazy. They are only instantiated when you call `instance` or `()`.

```dart
import 'package:lite_ref/lite_ref.dart';

// create a singleton
var dbRef = LiteRef(() => Database());

// use it
// refs are also callable so you can replace dbRef.instace with dbRef()
var db = await dbRef.instance.getPosts();

// override for testing
dbRef.overrideWith(() => MockDatabase());

// create a transient (always new instance)
var userServiceRef = LiteRef(() => UserService(database: dbRef()), cache: false);
```
