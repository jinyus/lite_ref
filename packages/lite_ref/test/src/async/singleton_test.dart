import 'package:flutter_test/flutter_test.dart';
import 'package:lite_ref/lite_ref.dart';

import '../common.dart';

const k10ms = Duration(milliseconds: 10);

void main() {
  test('returns cached instance', () async {
    final asyncRef = Ref.asyncSingleton<Point>(
      () async => Point(1, 2),
    );

    expect(asyncRef.hasInstance, isFalse);

    final firstInstance = await asyncRef();
    final secondInstance = await asyncRef();

    expect(firstInstance == secondInstance, isTrue);

    expect(asyncRef.hasInstance, isTrue);

    expect(asyncRef.assertInstance == firstInstance, isTrue);
  });

  test('returns same instance with race condition', () async {
    var count = 0;
    final asyncRef = Ref.asyncSingleton<Point>(
      () async {
        count++;
        await Future<void>.delayed(k10ms * count);
        return Point(1, 2);
      },
    );

    final (firstInstance, secondInstance) =
        await (asyncRef.instance, asyncRef.instance).wait;

    expect(firstInstance == secondInstance, isTrue);
  });

  test('should override with new create function', () async {
    final asyncRef = Ref.asyncSingleton<Point>(() async => Point(1, 2));

    final firstInstance = await asyncRef();
    expect(firstInstance.x, 1);

    await asyncRef.overrideWith(() async {
      return Point(3, 4);
    });

    final secondInstance = await asyncRef();
    expect(secondInstance.x, 3);
  });

  test('return new instance when overriding fails', () async {
    final asyncRef = Ref.asyncSingleton<Point>(
      () async {
        return Point(1, 2);
      },
    );

    final firstInstance = await asyncRef();
    expect(firstInstance.x, 1);

    var count = 0;

    await expectLater(
      () async => asyncRef.overrideWith(() async {
        count++;
        if (count == 1) throw Exception('Crashed $count');
        return Point(3, 4);
      }),
      throwsException,
    );

    expect(asyncRef.hasInstance, isFalse);

    final secondInstance = await asyncRef();

    expect(secondInstance.x, 3);

    expect(count, 2);
  });

  test('should throw when overriding frozen ref', () async {
    final asyncRef = Ref.asyncSingleton<Point>(() async => Point(1, 2));

    final firstInstance = await asyncRef();
    expect(firstInstance.x, 1);

    await asyncRef.overrideWith(() async {
      return Point(3, 4);
    });

    final secondInstance = await asyncRef();
    expect(secondInstance.x, 3);

    asyncRef.freeze();

    expect(
      () async => asyncRef.overrideWith(() async => Point(5, 6)),
      throwsStateError,
    );
  });

  test('should work with uninitialized ref', () async {
    late final AsyncSingletonRef<Point> asyncRef1;

    final asyncRef2 = Ref.asyncSingleton<Point>(
      () async {
        final yValue = (await asyncRef1()).y;
        return Point(1, yValue);
      },
    );

    asyncRef1 = Ref.asyncSingleton<Point>(() async {
      return Point(5, 6);
    });

    final ref1Instance = await asyncRef1();
    final ref2Instance = await asyncRef2();

    expect(ref1Instance.x, 5);
    expect(ref1Instance.y, 6);
    expect(ref2Instance.x, 1);
    expect(ref2Instance.y, 6);
  });

  test('should rerun create function if it crashed', () async {
    var count = 0;
    final asyncRef = Ref.asyncSingleton<Point>(
      () async {
        count++;
        if (count == 1) {
          throw Exception('Crashed $count');
        }
        return Point(1, 2);
      },
    );

    await expectLater(asyncRef.call, throwsException);

    expect(count, 1);

    expect(asyncRef.hasInstance, isFalse);

    expect(() => asyncRef.assertInstance, throwsStateError);

    final instance = await asyncRef();
    expect(instance.x, 1);
    expect(instance.y, 2);

    expect(count, 2);

    final secondInstance = await asyncRef();

    expect(instance == secondInstance, isTrue);

    expect(count, 2);
  });
}
