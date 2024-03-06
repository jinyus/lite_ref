import 'package:lite_ref_core/lite_ref_core.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  test('can be instantiated', () {
    expect(Ref.singleton<dynamic>(() => 1), isNotNull);
  });

  test('should lazily instantiate', () {
    var called = 0;

    Point create() {
      called++;
      return Point(1, 2);
    }

    final ref = Ref.singleton<Point>(create);

    expect(called, 0);

    ref.overrideWith(create);

    expect(called, 0);

    ref();

    expect(called, 1);

    ref();

    expect(called, 1);
  });

  test('returns same instance', () {
    final ref = Ref.singleton(() => Point(1, 2));
    expect(ref() == ref(), isTrue);
    expect(ref() == ref(), isTrue);
  });

  test('should override with new create function', () {
    final ref = Ref.singleton(() => Point(1, 2));

    expect(ref().x, 1);

    ref.overrideWith(() => Point(3, 4));

    expect(ref().x, 3);
  });
  test('should not override the instance if exception is thrown', () {
    final ref = Ref.singleton(() => Point(1, 2));

    expect(ref().x, 1);

    expect(() => ref.overrideWith(() => throw Exception()), throwsException);

    expect(ref().x, 1);
  });

  test('should try to recreate the instance if exception is thrown', () {
    var fail = true;
    var called = 0;
    final ref = Ref.singleton<Point>(
      () {
        called++;
        return fail ? throw Exception() : Point(1, 2);
      },
    );

    expect(ref.call, throwsException);

    expect(called, 1);

    fail = false;

    expect(ref().x, 1);

    expect(called, 2);

    expect(ref().x, 1);

    expect(called, 2);
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

  test('should throw when overriding frozen ref', () {
    final ref = Ref.singleton(() => Point(1, 2));

    expect(ref().x, 1);

    ref.overrideWith(() => Point(3, 4));

    expect(ref().x, 3);

    ref.freeze();

    expect(() => ref.overrideWith(() => Point(5, 6)), throwsStateError);
  });
}
