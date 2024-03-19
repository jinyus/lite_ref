import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lite_ref/lite_ref.dart';

void main() {
  test('overriden instance should be equal to main', () {
    final countRef = Ref.scoped((ctx) => 1);
    final countRefClone = countRef.overrideWith((ctx) => 2);

    expect(countRef, countRefClone);

    final hashSet = <Object>{}..add(countRef);

    expect(hashSet.contains(countRefClone), true);
  });

  testWidgets('should cache values', (tester) async {
    var ran = 0;
    final countRef = Ref.scoped((ctx) => ++ran);

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: Builder(
            builder: (context) {
              final val = countRef(context);
              final val2 = countRef(context);
              expect(val, 1);
              expect(val2, 1);
              return Text('$val $val2');
            },
          ),
        ),
      ),
    );

    expect(ran, 1);

    final txt = find.text('1 1');

    expect(txt, findsOneWidget);
  });

  testWidgets(
    'should throw when there is no root LiteRefScope',
    (tester) async {
      final countRef = Ref.scoped((ctx) => 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // This should trigger the error
              expect(() => countRef(context), throwsA(isA<AssertionError>()));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    },
  );

  testWidgets('overriden instance should have different value', (tester) async {
    final countRef = Ref.scoped((ctx) => 1);
    var val = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: Builder(
            builder: (context) {
              val = countRef(context);
              expect(val, 1);
              return LiteRefScope(
                overrides: [
                  countRef.overrideWith((ctx) => 2),
                ],
                child: Column(
                  children: [
                    Text('$val'),
                    Builder(
                      builder: (context) {
                        val = countRef(context);
                        expect(val, 2);
                        return Text('$val');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('should be able to use other refs', (tester) async {
    final ageRef = Ref.scoped((ctx) => 20);
    final nameRef = Ref.scoped((ctx) => 'John');

    final bioRef = Ref.scoped(
      (ctx) => '${nameRef(ctx)} is ${ageRef(ctx)} years old',
    );

    const correctText = 'John is 20 years old';

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: Builder(
            builder: (context) {
              final val = bioRef(context);
              expect(val, correctText);
              return Text(val);
            },
          ),
        ),
      ),
    );

    expect(find.text(correctText), findsOneWidget);
  });

  testWidgets('should dispose ref when scope is unmounted', (tester) async {
    final disposed = <int>[];
    final countRef = Ref.scoped((ctx) => 1, dispose: disposed.add);

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: Builder(
            builder: (context) {
              final val = countRef(context);
              expect(val, 1);
              return LiteRefScope(
                overrides: [
                  countRef.overrideWith((ctx) => 2),
                ],
                child: Builder(
                  builder: (context) {
                    final val = countRef(context);
                    expect(val, 2);
                    return Text('$val');
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);

    expect(disposed, isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: Builder(
            builder: (context) {
              final val = countRef(context);
              expect(val, 1);
              return Text('$val');
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(disposed, [2]); // overriden instance should be disposed

    await tester.pumpWidget(
      const MaterialApp(
        home: Text(''),
      ),
    );

    await tester.pumpAndSettle();

    expect(disposed, [2, 1]);
  });

  testWidgets(
      'should dispose ref when scope is unmounted when autodispose=false',
      (tester) async {
    final disposed = <int>[];
    final countRef = Ref.scoped(
      (ctx) => 1,
      dispose: disposed.add,
      autoDispose: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: Builder(
            builder: (context) {
              final val = countRef(context);
              expect(val, 1);
              return LiteRefScope(
                overrides: [
                  countRef.overrideWith((ctx) => 2),
                ],
                child: Builder(
                  builder: (context) {
                    final val = countRef(context);
                    expect(val, 2);
                    return Text('$val');
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);

    expect(disposed, isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: Builder(
            builder: (context) {
              final val = countRef(context);
              expect(val, 1);
              return Text('$val');
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(disposed, [2]); // overriden instance should be disposed

    await tester.pumpWidget(
      const MaterialApp(
        home: Text(''),
      ),
    );

    await tester.pumpAndSettle();

    expect(disposed, [2, 1]);
  });

  testWidgets('should dispose when only child is unmounted', (tester) async {
    final disposed = <int>[];
    final countRef = Ref.scoped((ctx) => 1, dispose: disposed.add);
    final show = ValueNotifier(true);

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: ListenableBuilder(
            listenable: show,
            builder: (context, snapshot) {
              if (!show.value) return const Text('hidden');
              return Builder(
                builder: (context) {
                  final val = countRef(context);
                  expect(val, 1);
                  return Text('$val');
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);

    expect(disposed, isEmpty);

    show.value = false;

    await tester.pumpAndSettle();

    expect(find.text('hidden'), findsOneWidget);

    expect(disposed, [1]);
  });

  testWidgets('should dispose when all children are unmounted', (tester) async {
    final disposed = <int>[];
    final countRef = Ref.scoped((ctx) => 1, dispose: disposed.add);
    final amount = ValueNotifier(3);

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: ListenableBuilder(
            listenable: amount,
            builder: (context, snapshot) {
              return Column(
                children: [
                  const SizedBox.shrink(),
                  for (var i = 0; i < amount.value; i++)
                    Builder(
                      builder: (context) {
                        final val = countRef(context);
                        expect(val, 1);
                        return Text('$val');
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1'), findsExactly(amount.value));

    expect(disposed, isEmpty);

    amount.value = 2;

    await tester.pumpAndSettle();

    expect(find.text('1'), findsExactly(amount.value));

    expect(disposed, isEmpty); // still has listeners

    amount.value = 0;

    await tester.pumpAndSettle();

    expect(find.text('1'), findsNothing);

    expect(disposed, [1]); // dispose when all children are unmounted
  });

  testWidgets(
    'should dispose Disposable when no dispose function is supplied',
    (tester) async {
      final resource = _Resource();
      final countRef = Ref.scoped((ctx) => resource);
      final show = ValueNotifier(true);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: ListenableBuilder(
              listenable: show,
              builder: (context, snapshot) {
                if (!show.value) return const Text('hidden');
                return Builder(
                  builder: (context) {
                    final val = countRef(context);
                    return Text('${val.disposed}');
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('false'), findsOneWidget);

      expect(resource.disposed, false);

      show.value = false;

      await tester.pumpAndSettle();

      expect(find.text('hidden'), findsOneWidget);

      expect(resource.disposed, true);
    },
  );

  testWidgets(
    'should dispose ValueNotifier when no dispose function is supplied',
    (tester) async {
      final vn = ValueNotifier(1);
      final countRef = Ref.scoped((ctx) => vn);
      final show = ValueNotifier(true);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: ListenableBuilder(
              listenable: show,
              builder: (context, snapshot) {
                if (!show.value) return const Text('hidden');
                return Builder(
                  builder: (context) {
                    final val = countRef(context);
                    return Text('${val.value}');
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);

      vn.addListener(() {}); // not disposed. ie: should not throw

      show.value = false;

      await tester.pumpAndSettle();

      expect(find.text('hidden'), findsOneWidget);

      // should throw when disposed
      expect(() => vn.addListener(() {}), throwsFlutterError);
    },
  );

  testWidgets(
    'should dispose correct instance when overriden',
    (tester) async {
      final resource = _Resource();
      final resource2 = _Resource();
      final countRef = Ref.scoped((ctx) => resource);
      final countRef2 = countRef.overrideWith((_) => resource2);
      final show = ValueNotifier(true);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: ListenableBuilder(
              listenable: show,
              builder: (context, snapshot) {
                return LiteRefScope(
                  overrides: [countRef2],
                  child: !show.value
                      ? const Text('hidden')
                      : Column(
                          children: [
                            Builder(
                              builder: (context) {
                                final val = countRef(context);
                                return Text('${val.disposed}');
                              },
                            ),
                            Builder(
                              builder: (context) {
                                final val = countRef(context);
                                return Text('${val.disposed}');
                              },
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('false'), findsExactly(2));

      expect(resource.disposed, false);
      expect(countRef.watchCount, 0);
      expect(resource2.disposed, false);
      expect(countRef2.watchCount, 2);

      show.value = false;

      await tester.pumpAndSettle();

      expect(find.text('hidden'), findsOneWidget);

      expect(resource.disposed, false);
      expect(countRef.watchCount, 0);
      expect(resource2.disposed, true);
      expect(countRef2.watchCount, 0);
    },
  );

  testWidgets(
    'should get correct value when GlobalKey changes '
    'causes it to move its position in the tree',
    (tester) async {
      final current = ValueNotifier(1);
      final countRef = Ref.scoped((ctx) => 0);

      final child = Builder(
        key: GlobalKey(),
        builder: (context) {
          final val = countRef.of(context);
          return Text('got: $val');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Column(
              children: [
                ListenableBuilder(
                  listenable: current,
                  builder: (context, snapshot) {
                    if (current.value != 1) {
                      return const SizedBox.shrink();
                    }
                    return LiteRefScope(
                      overrides: [
                        countRef.overrideWith((_) => 1),
                      ],
                      child: Builder(
                        builder: (context) => child,
                      ),
                    );
                  },
                ),
                ListenableBuilder(
                  listenable: current,
                  builder: (context, snapshot) {
                    if (current.value != 2) {
                      return const SizedBox.shrink();
                    }
                    return LiteRefScope(
                      overrides: [
                        countRef.overrideWith((_) => 2),
                      ],
                      child: Builder(
                        builder: (context) => child,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('got: 1'), findsOneWidget);
      current.value = 2;
      await tester.pumpAndSettle();
      expect(find.text('got: 2'), findsOneWidget);
    },
  );
  testWidgets(
    'should return true if the ScopedRef is '
    'initialized in the current LiteRefScope',
    (tester) async {
      final countRef = Ref.scoped((ctx) => 1);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final initialized = countRef.exists(context);
                expect(initialized, false);

                final val = countRef.of(context);
                expect(val, 1);

                final initialized2 = countRef.exists(context);
                expect(initialized2, true);

                return LiteRefScope(
                  overrides: [
                    countRef.overrideWith((ctx) => 2),
                  ],
                  child: Builder(
                    builder: (context) {
                      final initialized = countRef.exists(context);
                      expect(initialized, false);

                      final val = countRef.of(context);
                      expect(val, 2);

                      final initialized2 = countRef.exists(context);
                      expect(initialized2, true);

                      return Text('$val');
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets(
    'should dispose when all children are unmounted and it is read in parent',
    (tester) async {
      final disposed = <int>[];
      final countRef = Ref.scoped((ctx) => 1, dispose: disposed.add);
      final amount = ValueNotifier(3);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    return Text('read ${countRef.read(context)}');
                  },
                ),
                ListenableBuilder(
                  listenable: amount,
                  builder: (context, snapshot) {
                    return Column(
                      children: [
                        const SizedBox.shrink(),
                        for (var i = 0; i < amount.value; i++)
                          Builder(
                            builder: (context) {
                              final val = countRef(context);
                              expect(val, 1);
                              return Text('$val');
                            },
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1'), findsExactly(amount.value));
      expect(find.text('read 1'), findsOneWidget);

      expect(disposed, isEmpty);

      amount.value = 2;

      await tester.pumpAndSettle();

      expect(find.text('1'), findsExactly(amount.value));

      expect(disposed, isEmpty); // still has listeners

      amount.value = 0;

      await tester.pumpAndSettle();

      expect(find.text('1'), findsNothing);

      expect(disposed, [1]); // dispose when all children are unmounted
      expect(find.text('read 1'), findsOneWidget);
    },
  );

  testWidgets(
      'should NOT dispose ref when scope is unmounted and only access was a "read"',
      (tester) async {
    final disposed = <int>[];
    final countRef = Ref.scoped((ctx) => 1, dispose: disposed.add);
    final show = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: ValueListenableBuilder(
            valueListenable: show,
            builder: (__, value, _) {
              if (!value) return const SizedBox.shrink();
              return Builder(
                builder: (context) {
                  final val = countRef.read(context);
                  expect(val, 1);
                  return Text('$val');
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(disposed, isEmpty); // overriden instance should be disposed

    show.value = false;

    await tester.pumpAndSettle();

    expect(disposed, isEmpty);
  });
}

class _Resource implements Disposable {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
  }
}
