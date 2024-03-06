import 'package:flutter_test/flutter_test.dart';
import 'package:lite_ref/lite_ref.dart';

import '../common.dart';

void main() {
  test('returns fresh instance', () async {
    final asyncRef = Ref.asyncTransient<Point>(
      () async => Point(1, 2),
    );

    final firstInstance = await asyncRef();
    final secondInstance = await asyncRef();

    expect(firstInstance == secondInstance, isFalse);
  });

  test('should override with new create function', () async {
    final asyncRef = Ref.asyncTransient<Point>(() async => Point(1, 2));

    final firstInstance = await asyncRef();
    expect(firstInstance.x, 1);

    asyncRef.overrideWith(() async {
      return Point(3, 4);
    });

    final secondInstance = await asyncRef();
    expect(secondInstance.x, 3);
  });

  test('throws when overriding frozen ref', () async {
    final asyncRef = Ref.asyncTransient<Point>(() async => Point(1, 2));

    final firstInstance = await asyncRef();

    expect(firstInstance.x, 1);

    asyncRef.overrideWith(() async {
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
}
