// ignore_for_file: prefer_const_constructors, cascade_invocations

import 'package:lite_ref/lite_ref.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  test('can be instantiated', () {
    expect(Ref.singleton<dynamic>(() => 1), isNotNull);
  });

  test('returns cached instance', () {
    final ref = Ref.singleton(() => Point(1, 2));
    expect(ref() == ref(), isTrue);
  });

  test('returns fresh instance', () {
    final ref = Ref.transient(() => Point(1, 2));
    expect(ref() == ref(), isFalse);
  });

  test('override singleton with new create function', () {
    final ref = Ref.singleton(() => Point(1, 2));

    expect(ref().x, 1);

    ref.overrideWith(() => Point(3, 4));

    expect(ref().x, 3);
  });

  test('override transient with new create function', () {
    final ref = Ref.transient(() => Point(1, 2));

    expect(ref().x, 1);

    ref.overrideWith(() => Point(3, 4));

    expect(ref().x, 3);
  });

  test('throws when overriding frozen ref', () {
    final ref = Ref.singleton(() => Point(1, 2));

    expect(ref().x, 1);

    ref.overrideWith(() => Point(3, 4));

    expect(ref().x, 3);

    ref.freeze();

    expect(() => ref.overrideWith(() => Point(5, 6)), throwsStateError);
  });

  test('should work with uninitialized ref', () {
    late final SingletonRef<Point> ref1;
    final ref2 = Ref.singleton(() => Point(1, ref1().y));

    ref1 = Ref.singleton(() => Point(5, 6));

    expect(ref1().x, 5);
    expect(ref1().y, 6);
    expect(ref2().x, 1);
    expect(ref2().y, 6);
  });
}
