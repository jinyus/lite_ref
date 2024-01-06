import 'package:lite_ref/lite_ref.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() {
  test('should freeze all refs', () async {
    final refs = Ref.singleton<Point?>(create: () => Point(1, 2));
    final reft = Ref.transient<Point?>(create: () => Point(3, 4));
    final arefs = Ref.asyncSingleton<Point?>(create: () async => Point(5, 6));
    final areft = Ref.asyncTransient<Point?>(create: () async => Point(7, 8));

    // does not throw
    refs.overrideWith(() => null);
    reft.overrideWith(() => null);
    await arefs.overrideWith(() async => null);
    areft.overrideWith(() async => null);

    Ref.freezeAll();

    expect(() => refs.overrideWith(() => null), throwsStateError);
    expect(() => reft.overrideWith(() => null), throwsStateError);
    expect(() => arefs.overrideWith(() async => null), throwsStateError);
    expect(() => areft.overrideWith(() async => null), throwsStateError);
  });
}
