import 'package:lite_ref/src/async_ref.dart';
import 'package:test/test.dart';

import 'ref_test.dart';

void main() {
  test('returns cached instance', () async {
    final asyncRef = LiteAsyncRef<Point>(
      create: () async => Point(1, 2),
    );

    final firstInstance = await asyncRef();
    final secondInstance = await asyncRef();

    expect(firstInstance == secondInstance, isTrue);
  });

  test('returns fresh instance', () async {
    final asyncRef = LiteAsyncRef<Point>(
      create: () async => Point(1, 2),
      cache: false,
    );

    final firstInstance = await asyncRef();
    final secondInstance = await asyncRef();

    expect(firstInstance == secondInstance, isFalse);
  });

  test('override value with new create function', () async {
    final asyncRef = LiteAsyncRef<Point>(create: () async => Point(1, 2));

    final firstInstance = await asyncRef();
    expect(firstInstance.x, 1);

    await asyncRef.overrideWith(() async {
      return Point(3, 4);
    });

    final secondInstance = await asyncRef();
    expect(secondInstance.x, 3);
  });

  test('lazy create function should work', () async {
    final asyncRef = LiteAsyncRef<Point>();

    await asyncRef.overrideWith(() async => Point(1, 2));

    final instance = await asyncRef();
    expect(instance, isA<Point>());
  });

  test('throws when creation function not set', () async {
    final asyncRef = LiteAsyncRef<Point>();

    expect(() async => asyncRef(), throwsStateError);
  });

  test('should work with uninitialized ref', () async {
    final asyncRef1 = LiteAsyncRef<Point>();
    final asyncRef2 = LiteAsyncRef<Point>(
      create: () async {
        final yValue = (await asyncRef1()).y;
        return Point(1, yValue);
      },
    );

    await asyncRef1.overrideWith(() async {
      return Point(5, 6);
    });

    final ref1Instance = await asyncRef1();
    final ref2Instance = await asyncRef2();

    expect(ref1Instance.x, 5);
    expect(ref1Instance.y, 6);
    expect(ref2Instance.x, 1);
    expect(ref2Instance.y, 6);
  });

  test('should rerun create function is it crashed', () async {
    var count = 0;
    final asyncRef = LiteAsyncRef<Point>(
      create: () async {
        count++;
        if (count == 1) {
          throw Exception('Crashed');
        }
        return Point(1, 2);
      },
    );

    expect(() async => asyncRef(), throwsException);

    final instance = await asyncRef();
    expect(instance.x, 1);
    expect(instance.y, 2);

    expect(count, 2);

    final secondInstance = await asyncRef();

    expect(instance == secondInstance, isTrue);

    expect(count, 2);
  });
}
