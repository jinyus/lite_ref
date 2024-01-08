// ignore_for_file: prefer_const_constructors, cascade_invocations

import 'package:lite_ref/lite_ref.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  test('can be instantiated', () {
    expect(Ref.transient<dynamic>(() => 1), isNotNull);
  });

  test('returns fresh instance', () {
    final ref = Ref.transient(() => Point(1, 2));
    expect(ref() == ref(), isFalse);
  });

  test('should override with new create function', () {
    final ref = Ref.transient(() => Point(1, 2));

    expect(ref().x, 1);

    ref.overrideWith(() => Point(3, 4));

    expect(ref().x, 3);
  });

  test('throws when overriding frozen ref', () {
    final ref = Ref.transient(() => Point(1, 2));

    expect(ref().x, 1);

    ref.overrideWith(() => Point(3, 4));

    expect(ref().x, 3);

    ref.freeze();

    expect(() => ref.overrideWith(() => Point(5, 6)), throwsStateError);
  });
}
