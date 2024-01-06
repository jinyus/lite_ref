// ignore_for_file: prefer_const_constructors, cascade_invocations

import 'package:lite_ref/src/ref.dart';
import 'package:test/test.dart';

class Point {
  Point(this.x, this.y);

  final int x;
  final int y;
}

void main() {
  test('can be instantiated', () {
    expect(LiteRef<dynamic>(), isNotNull);
  });

  test('returns cached instance', () {
    final ref = LiteRef(create: () => Point(1, 2));
    expect(ref() == ref(), isTrue);
  });

  test('returns fresh instance', () {
    final ref = LiteRef(create: () => Point(1, 2), cache: false);
    expect(ref() == ref(), isFalse);
  });

  test('override value with new create function', () {
    final ref = LiteRef(create: () => Point(1, 2));

    expect(ref().x, 1);

    ref.overrideWith(() => Point(3, 4));

    expect(ref().x, 3);
  });

  test('throws when overriding frozen ref', () {
    final ref = LiteRef(create: () => Point(1, 2));

    expect(ref().x, 1);

    ref.overrideWith(() => Point(3, 4));

    expect(ref().x, 3);

    ref.freeze();

    expect(() => ref.overrideWith(() => Point(5, 6)), throwsStateError);
  });

  test('lazy create function should work', () {
    final ref = LiteRef<Point>();

    ref.overrideWith(() => Point(1, 2));

    expect(ref(), isA<Point>());
  });

  test('throws when creation function not set', () {
    final ref = LiteRef<Point>();

    expect(ref.call, throwsStateError);
  });

  test('should work with uninitialized ref', () {
    final ref1 = LiteRef<Point>();
    final ref2 = LiteRef(create: () => Point(1, ref1().y));

    ref1.overrideWith(() => Point(5, 6));

    expect(ref1().x, 5);
    expect(ref1().y, 6);
    expect(ref2().x, 1);
    expect(ref2().y, 6);
  });
}
