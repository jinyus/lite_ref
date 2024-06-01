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
                overrides: {
                  countRef.overrideWith((ctx) => 2),
                },
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
                overrides: {
                  countRef.overrideWith((ctx) => 2),
                },
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
                overrides: {
                  countRef.overrideWith((ctx) => 2),
                },
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
                  overrides: {countRef2},
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
      expect(resource2.disposed, false);

      show.value = false;

      await tester.pumpAndSettle();

      expect(find.text('hidden'), findsOneWidget);

      expect(resource.disposed, false);
      expect(resource2.disposed, true);
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
                      overrides: {
                        countRef.overrideWith((_) => 1),
                      },
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
                      overrides: {
                        countRef.overrideWith((_) => 2),
                      },
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
                  overrides: {
                    countRef.overrideWith((ctx) => 2),
                  },
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
    'should NOT dispose when scope is unmounted and only access was a "read"',
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
    },
  );

  testWidgets(
    'should throw when the scope is marked as onlyOverrides',
    (tester) async {
      final countRef = Ref.scoped((ctx) => 1);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            onlyOverrides: true,
            child: Builder(
              builder: (context) {
                late final val = countRef(context);
                expect(() => val, throwsException);
                return const Text('1');
              },
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
    },
  );

  testWidgets('should fetch from the closest scope', (tester) async {
    final resourceRef = Ref.scoped((ctx) => _Resource());

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: Builder(
            builder: (context) {
              final val = resourceRef(context);
              expect(val.disposed, false);
              val.disposed = true;
              return LiteRefScope(
                onlyOverrides: true,
                overrides: {resourceRef.overrideWith((ctx) => _Resource())},
                child: Builder(
                  builder: (context) {
                    final val2 = resourceRef(context);
                    expect(val2.disposed, false);
                    return Text('${val2.disposed}');
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('false'), findsOneWidget);
  });

  testWidgets('should fetch from the closest scope/2 depth', (tester) async {
    final resourceRef = Ref.scoped((ctx) => _Resource());

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: Builder(
            builder: (context) {
              final val = resourceRef(context);
              expect(val.disposed, false);
              val.disposed = true;
              return LiteRefScope(
                onlyOverrides: true,
                overrides: {resourceRef.overrideWith((ctx) => _Resource())},
                child: Builder(
                  builder: (context) {
                    return LiteRefScope(
                      onlyOverrides: true,
                      child: Builder(
                        builder: (context) {
                          final val2 = resourceRef(context);
                          expect(val2.disposed, false);
                          return Text('${val2.disposed}');
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('false'), findsOneWidget);
  });

  testWidgets('should fetch from the closest scope/3 depth', (tester) async {
    final resourceRef = Ref.scoped((ctx) => _Resource());

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: Builder(
            builder: (context) {
              final val = resourceRef(context);
              expect(val.disposed, false);
              val.disposed = true;
              return LiteRefScope(
                onlyOverrides: true,
                overrides: {resourceRef.overrideWith((ctx) => _Resource())},
                child: Builder(
                  builder: (context) {
                    return LiteRefScope(
                      onlyOverrides: true,
                      child: Builder(
                        builder: (context) {
                          return LiteRefScope(
                            onlyOverrides: true,
                            child: Builder(
                              builder: (context) {
                                final val2 = resourceRef(context);
                                expect(val2.disposed, false);
                                return Text('${val2.disposed}');
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('false'), findsOneWidget);
  });

  testWidgets(
    'should fetch from the parent scope when the '
    'closest scope is marked as onlyOverrides',
    (tester) async {
      final resourceRef = Ref.scoped((ctx) => _Resource());

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final val = resourceRef(context);
                expect(val.disposed, false);
                val.disposed = true;
                return LiteRefScope(
                  onlyOverrides: true,
                  child: Builder(
                    builder: (context) {
                      final val = resourceRef(context);
                      expect(val.disposed, true);
                      return Text('${val.disposed}');
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('true'), findsOneWidget);
    },
  );

  testWidgets('should dispose correct ref when scope has UniqueKey',
      (tester) async {
    final disposed = <int>[];
    final countRef = Ref.scoped(
      (ctx) => 1,
      dispose: disposed.add,
    );

    final inc = ValueNotifier(1);

    await tester.pumpWidget(
      MaterialApp(
        home: LiteRefScope(
          child: ListenableBuilder(
            listenable: inc,
            builder: (context, _) {
              return Container(
                key: UniqueKey(),
                child: LiteRefScope(
                  overrides: {
                    countRef.overrideWith((ctx) => 1 + inc.value),
                  },
                  child: Builder(
                    builder: (context) {
                      final val = countRef(context);
                      return Text('$val');
                    },
                  ),
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

    inc.value = 2;

    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);

    expect(disposed, [2]);

    inc.value = 3;

    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);

    expect(disposed, [2, 3]);
  });

  group('Scoped async', () {
    test('overridden instance should be equal to main', () {
      final asyncRef = Ref.scopedAsync((context) async => 1);
      final asyncRefClone = asyncRef.overrideWith((context) async => 2);

      expect(asyncRef, asyncRefClone);

      final hashSet = <Object>{}..add(asyncRef);

      expect(hashSet.contains(asyncRefClone), true);
    });

    testWidgets('should cache values', (tester) async {
      var ran = 0;
      final asyncRef = Ref.scopedAsync((context) async => ++ran);

      const firstWidgetKey = Key('first widget');
      const secondWidgetKey = Key('second widget');

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                return Column(
                  children: [
                    FutureBuilder(
                      future: asyncRef(context),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          final val = snapshot.data;
                          expect(val, 1);
                          return Text('$val', key: firstWidgetKey);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    FutureBuilder(
                      future: asyncRef(context),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          final val = snapshot.data;
                          expect(val, 1);
                          return Text('$val', key: secondWidgetKey);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(ran, 1);

      // The widgets are not built yet
      final first = find.byKey(firstWidgetKey);
      final second = find.byKey(secondWidgetKey);
      expect(first, findsNothing);
      expect(second, findsNothing);

      await tester.pumpAndSettle();

      // The widgets are built
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);

      // The widgets have the correct value
      final firstData = tester.widget<Text>(first).data;
      final secondData = tester.widget<Text>(second).data;
      expect(firstData, '1');
      expect(secondData, '1');
    });

    testWidgets(
      'should throw when there is no root LiteRefScope',
      (tester) async {
        final countRef = Ref.scopedAsync((context) async => 1);
        Object? error;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return FutureBuilder(
                  future: countRef.of(context),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      error = snapshot.error;
                      return const SizedBox.shrink();
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        );
        // FutureBuilder loads the future in the next frame
        expect(error, isNull);

        await tester.pumpAndSettle();

        // This should trigger the error
        expect(error, isA<AssertionError>());
      },
    );

    testWidgets('overridden instance should have different value',
        (tester) async {
      final countRef = Ref.scopedAsync((ctx) async => 1);
      var val2 = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                return FutureBuilder(
                  future: countRef.of(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      final val1 = snapshot.requireData;
                      expect(val1, 1);
                      return LiteRefScope(
                        overrides: {
                          countRef.overrideWith((ctx) async => 2),
                        },
                        child: Builder(
                          builder: (context) {
                            return FutureBuilder(
                              future: countRef.of(context),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  val2 = snapshot.requireData;
                                  expect(val2, 2);
                                  return Text('$val1 $val2');
                                }
                                return const SizedBox.shrink();
                              },
                            );
                          },
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 2'), findsOneWidget);
    });

    testWidgets('should be able to use other refs', (tester) async {
      final nameRef = Ref.scoped((context) => 'John');
      final ageRef = Ref.scopedAsync((context) async => 20);

      final bioRef = Ref.scopedAsync(
            (ctx) async {
              final name = nameRef(ctx);
              final age = await ageRef(ctx);
              return '$name is $age years old';
            },
      );

      const correctText = 'John is 20 years old';
      const textKey = Key('text');

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                return FutureBuilder(
                  future: bioRef.of(context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      final val = snapshot.requireData;
                      expect(val, correctText);
                      return Text(val, key: textKey);
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ),
      );
      final finder = find.byKey(textKey);

      expect(finder, findsNothing);

      await tester.pumpAndSettle();

      expect(finder, findsOneWidget);
      expect(find.text(correctText), findsOneWidget);
    });
  });

  group('ScopedFamilyRef', () {
    test('overridden instance should be equal to main', () {
      final countRef = Ref.scopedFamily((ctx, int a) => 1);
      final countRefClone = countRef.overrideWith((ctx, int a) => 2);

      expect(countRef, countRefClone);

      final hashSet = <Object>{}..add(countRef);

      expect(hashSet.contains(countRefClone), true);
    });

    testWidgets('should cache values', (tester) async {
      var ran = 0;
      final countRef = Ref.scopedFamily((ctx, int a) => ++ran);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final val = countRef(context, 1);
                final val2 = countRef(context, 1);
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

    testWidgets('family should return different values', (tester) async {
      final countRef = Ref.scopedFamily((ctx, int a) => 1 + a);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final val = countRef(context, 0);
                final val2 = countRef(context, 1);
                expect(val, 1);
                expect(val2, 2);
                return Text('$val $val2');
              },
            ),
          ),
        ),
      );

      final txt = find.text('1 2');

      expect(txt, findsOneWidget);
    });

    testWidgets(
      'should throw when there is no root LiteRefScope',
      (tester) async {
        final countRef = Ref.scopedFamily((ctx, String family) => 1);

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                // This should trigger the error
                expect(
                  () => countRef(context, 'one'),
                  throwsA(isA<AssertionError>()),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );

    testWidgets('overridden instance should return different instances',
        (tester) async {
      final controllerRef = Ref.scopedFamily(
        (ctx, int family) => _Controller(id: family),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final controller = controllerRef(context, 42);
                expect(
                  controller,
                  isA<_Controller>()
                      .having((p0) => p0.id, 'id', 42)
                      .having((p0) => p0.value, 'value', 0),
                );
                return LiteRefScope(
                  overrides: {
                    controllerRef.overrideWith(
                      (ctx, int _) => _Controller(id: 0, value: 1),
                    ),
                  },
                  child: Column(
                    children: [
                      Text('${controller.value}'),
                      Builder(
                        builder: (context) {
                          final controller = controllerRef(context, 42);
                          expect(
                            controller,
                            isA<_Controller>()
                                .having((p0) => p0.id, 'id', 0)
                                .having((p0) => p0.value, 'value', 1),
                          );
                          return Text('${controller.value}');
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

      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should be able to use other refs', (tester) async {
      final statusValue = Ref.scoped((context) => 200);
      final controller = Ref.scopedFamily((context, int id) {
        final status = statusValue.of(context);
        return _Controller(id: id, value: status);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final controller1 = controller(context, 1);
                expect(
                  controller1,
                  isA<_Controller>()
                      .having((p0) => p0.id, 'id', 1)
                      .having((p0) => p0.value, 'status', 200),
                );
                return Text(
                  'id: ${controller1.id}, status: ${controller1.value}',
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('id: 1, status: 200'), findsOneWidget);
    });

    testWidgets('should dispose family when scope is unmounted',
        (tester) async {
      final disposed = <int>[];
      final countRef = Ref.scopedFamily(
        (ctx, int family) => 0 + family,
        dispose: disposed.add,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final val = countRef(context, 1);
                expect(val, 1);
                final val2 = countRef(context, 2);
                expect(val2, 2);
                return LiteRefScope(
                  overrides: {
                    countRef.overrideWith((ctx, f) => 3),
                  },
                  child: Builder(
                    builder: (context) {
                      final val = countRef(context, 1);
                      expect(val, 3);
                      return Text('$val $val2');
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('3 2'), findsOneWidget);

      expect(disposed, isEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final val = countRef(context, 1);
                expect(val, 1);
                final val2 = countRef(context, 2);
                expect(val2, 2);
                return Text('$val $val2');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 2'), findsOneWidget);
      expect(disposed, [3]); // overridden instance should be disposed

      await tester.pumpWidget(
        const MaterialApp(
          home: LiteRefScope(child: Text('')),
        ),
      );

      await tester.pumpAndSettle();

      expect(disposed, [3, 1, 2]); // all instances should be disposed
    });

    testWidgets(
        'should dispose family when scope is unmounted when autodispose=false',
        (tester) async {
      final disposed = <int>[];
      final countRef = Ref.scopedFamily(
        (ctx, int f) => 0 + f,
        dispose: disposed.add,
        autoDispose: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final val = countRef(context, 1);
                expect(val, 1);
                final val2 = countRef(context, 2);
                expect(val2, 2);
                return LiteRefScope(
                  overrides: {
                    countRef.overrideWith((ctx, f) => 3),
                  },
                  child: Builder(
                    builder: (context) {
                      final val = countRef(context, 1);
                      expect(val, 3);
                      return Text('$val $val2');
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('3 2'), findsOneWidget);
      expect(disposed, isEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final val = countRef(context, 1);
                expect(val, 1);
                final val2 = countRef(context, 2);
                expect(val2, 2);
                return Text('$val $val2');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 2'), findsOneWidget);
      expect(disposed, [3]); // overridden instance should be disposed

      await tester.pumpWidget(
        const MaterialApp(
          home: Text(''),
        ),
      );

      await tester.pumpAndSettle();

      expect(disposed, [3, 1, 2]);
    });

    testWidgets('should dispose family when only child is unmounted',
        (tester) async {
      final disposed = <int>[];
      final countRef = Ref.scopedFamily(
        (ctx, int f) => 0 + f,
        dispose: disposed.add,
      );
      final show = ValueNotifier(true);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final val0 = countRef(context, 0);
                return ListenableBuilder(
                  listenable: show,
                  builder: (context, snapshot) {
                    if (!show.value) {
                      return Column(
                        children: [
                          const Text('hidden'),
                          Text('$val0'),
                        ],
                      );
                    }
                    return Builder(
                      builder: (context) {
                        final val1 = countRef(context, 1);
                        expect(val1, 1);
                        return Text('$val0 $val1');
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0 1'), findsOneWidget);

      expect(disposed, isEmpty);

      show.value = false;

      await tester.pumpAndSettle();

      expect(find.text('hidden'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      expect(disposed, [1]);
    });

    testWidgets('should dispose family when all children are unmounted',
        (tester) async {
      final disposed = <int>[];
      final countRef = Ref.scopedFamily(
        (ctx, int f) => 0 + f,
        dispose: disposed.add,
      );
      final amount = ValueNotifier(3);

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: ListenableBuilder(
              listenable: amount,
              builder: (context, snapshot) {
                final val0 = countRef(context, 0);
                return Column(
                  children: [
                    Text('$val0'),
                    for (var i = 0; i < amount.value; i++)
                      Builder(
                        builder: (context) {
                          final val1 = countRef(context, 1);
                          expect(val1, 1);
                          return Text('$val1');
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

      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsExactly(amount.value));

      expect(disposed, isEmpty);

      amount.value = 2;

      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsExactly(amount.value));

      expect(disposed, isEmpty); // still has listeners

      amount.value = 0;

      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      expect(disposed, [1]); // dispose when all children are unmounted
    });

    testWidgets(
      'should dispose a Disposable family when no dispose function is supplied',
      (tester) async {
        final resources = <int, _Resource>{};
        final countRef = Ref.scopedFamily((ctx, int f) {
          return resources.putIfAbsent(f, _Resource.new);
        });
        final show = ValueNotifier(true);

        await tester.pumpWidget(
          MaterialApp(
            home: LiteRefScope(
              child: ListenableBuilder(
                listenable: show,
                builder: (context, snapshot) {
                  final val0 = countRef(context, 0);
                  return Column(
                    children: [
                      Text('val0: ${val0.disposed}'),
                      if (!show.value)
                        const Text('hidden')
                      else
                        Builder(
                          builder: (context) {
                            final val1 = countRef(context, 1);
                            return Text('val1: ${val1.disposed}');
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

        expect(find.text('val0: false'), findsOneWidget);
        expect(find.text('val1: false'), findsOneWidget);

        expect(
          resources[0],
          isA<_Resource>().having((p0) => p0.disposed, 'disposed', false),
        );
        expect(
          resources[1],
          isA<_Resource>().having((p0) => p0.disposed, 'disposed', false),
        );

        show.value = false;

        await tester.pumpAndSettle();

        expect(find.text('val0: false'), findsOneWidget);
        expect(find.text('hidden'), findsOneWidget);

        expect(
          resources[0],
          isA<_Resource>().having((p0) => p0.disposed, 'disposed', false),
        );
        expect(
          resources[1],
          isA<_Resource>().having((p0) => p0.disposed, 'disposed', true),
        );
      },
    );

    testWidgets(
      'should dispose ValueNotifier in a family scope '
      'when no dispose function is supplied',
      (tester) async {
        final vn = ValueNotifier(1);
        final countRef = Ref.scopedFamily((ctx, int _) => vn);
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
                      final val = countRef(context, 0);
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
      'should dispose correct family instance when override',
      (tester) async {
        final resource = _Resource();
        final resource2 = _Resource();
        final countRef = Ref.scopedFamily((ctx, String _) => resource);
        final countRef2 = countRef.overrideWith((_, __) => resource2);
        final show = ValueNotifier(true);

        await tester.pumpWidget(
          MaterialApp(
            home: LiteRefScope(
              child: ListenableBuilder(
                listenable: show,
                builder: (context, snapshot) {
                  return LiteRefScope(
                    overrides: {countRef2},
                    child: !show.value
                        ? const Text('hidden')
                        : Column(
                            children: [
                              Builder(
                                builder: (context) {
                                  final val = countRef(context, '1');
                                  return Text('${val.disposed}');
                                },
                              ),
                              Builder(
                                builder: (context) {
                                  final val = countRef(context, '1');
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
        expect(resource2.disposed, false);

        show.value = false;

        await tester.pumpAndSettle();

        expect(find.text('hidden'), findsOneWidget);

        expect(resource.disposed, false);
        expect(resource2.disposed, true);
      },
    );

    testWidgets(
      'should get correct family value when GlobalKey changes '
      'causes it to move its position in the tree',
      (tester) async {
        final current = ValueNotifier(1);
        final countRef = Ref.scopedFamily((ctx, int _) => 0);

        final child = Builder(
          key: GlobalKey(),
          builder: (context) {
            final val = countRef.of(context, 0);
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
                        overrides: {
                          countRef.overrideWith((_, __) => 1),
                        },
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
                        overrides: {
                          countRef.overrideWith((_, __) => 2),
                        },
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
      'should return true if the ScopedFamilyRef is '
      'initialized in the current LiteRefScope',
      (tester) async {
        final countRef = Ref.scopedFamily((ctx, int f) => 0 + f);

        await tester.pumpWidget(
          MaterialApp(
            home: LiteRefScope(
              child: Builder(
                builder: (context) {
                  final initialized1 = countRef.exists(context, 1);
                  final initialized2 = countRef.exists(context, 2);
                  expect(initialized1, false);
                  expect(initialized2, false);

                  final val = countRef.of(context, 1);
                  expect(val, 1);

                  final initialized1After = countRef.exists(context, 1);
                  final initialized2After = countRef.exists(context, 2);
                  expect(initialized1After, true);
                  expect(initialized2After, false);

                  return LiteRefScope(
                    overrides: {
                      countRef.overrideWith((ctx, f) => 10 + f),
                    },
                    child: Builder(
                      builder: (context) {
                        final initialized1 = countRef.exists(context, 1);
                        final initialized2 = countRef.exists(context, 2);
                        expect(initialized1, false);
                        expect(initialized2, false);

                        final val = countRef.of(context, 1);
                        expect(val, 11);

                        final initialized1After = countRef.exists(context, 1);
                        final initialized2After = countRef.exists(context, 2);
                        expect(initialized1After, true);
                        expect(initialized2After, false);

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

        expect(find.text('11'), findsOneWidget);
      },
    );

    testWidgets(
      'LiteRefScope should dispose when all children '
      'are unmounted and it is read in parent',
      (tester) async {
        final disposed = <int>[];
        final countRef = Ref.scopedFamily(
          (ctx, int f) => 0 + f,
          dispose: disposed.add,
        );
        final amount = ValueNotifier(3);

        await tester.pumpWidget(
          MaterialApp(
            home: LiteRefScope(
              child: Column(
                children: [
                  Builder(
                    builder: (context) {
                      return Text('read ${countRef.read(context, 1)}');
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
                                final val = countRef(context, 1);
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
      'LiteRefScope should NOT dispose when scope '
      'is unmounted and only access was a "read"',
      (tester) async {
        final disposed = <int>[];
        final countRef = Ref.scopedFamily(
          (ctx, int f) => 0 + f,
          dispose: disposed.add,
        );
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
                      final val = countRef.read(context, 1);
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
        expect(disposed, isEmpty); // overridden instance should be disposed

        show.value = false;

        await tester.pumpAndSettle();

        expect(disposed, isEmpty);
      },
    );

    testWidgets(
      'LiteRefScope should throw when the scope is marked as onlyOverrides',
      (tester) async {
        final countRef = Ref.scopedFamily((ctx, int f) => 0 + f);

        await tester.pumpWidget(
          MaterialApp(
            home: LiteRefScope(
              onlyOverrides: true,
              child: Builder(
                builder: (context) {
                  late final val = countRef(context, 0);
                  expect(() => val, throwsException);
                  return const Text('1');
                },
              ),
            ),
          ),
        );

        expect(find.text('1'), findsOneWidget);
      },
    );

    testWidgets('LiteRefScope should fetch from the closest scope',
        (tester) async {
      final resourceRef = Ref.scopedFamily((ctx, int f) => _Resource());

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final val = resourceRef(context, 0);
                expect(val.disposed, false);
                val.disposed = true;
                return LiteRefScope(
                  onlyOverrides: true,
                  overrides: {
                    resourceRef.overrideWith((ctx, int _) => _Resource()),
                  },
                  child: Builder(
                    builder: (context) {
                      final val2 = resourceRef(context, 0);
                      expect(val2.disposed, false);
                      return Text('${val2.disposed}');
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('false'), findsOneWidget);
    });

    testWidgets('LiteRefScope should fetch from the closest scope/2 depth',
        (tester) async {
      final resourceRef = Ref.scopedFamily((ctx, int f) => _Resource());

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final val = resourceRef(context, 0);
                expect(val.disposed, false);
                val.disposed = true;
                return LiteRefScope(
                  onlyOverrides: true,
                  overrides: {
                    resourceRef.overrideWith((ctx, _) => _Resource()),
                  },
                  child: Builder(
                    builder: (context) {
                      return LiteRefScope(
                        onlyOverrides: true,
                        child: Builder(
                          builder: (context) {
                            final val2 = resourceRef(context, 0);
                            expect(val2.disposed, false);
                            return Text('${val2.disposed}');
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('false'), findsOneWidget);
    });

    testWidgets('LiteRefScope should fetch from the closest scope/3 depth',
        (tester) async {
      final resourceRef = Ref.scopedFamily((ctx, int f) => _Resource());

      await tester.pumpWidget(
        MaterialApp(
          home: LiteRefScope(
            child: Builder(
              builder: (context) {
                final val = resourceRef(context, 0);
                expect(val.disposed, false);
                val.disposed = true;
                return LiteRefScope(
                  onlyOverrides: true,
                  overrides: {
                    resourceRef.overrideWith((ctx, _) => _Resource()),
                  },
                  child: Builder(
                    builder: (context) {
                      return LiteRefScope(
                        onlyOverrides: true,
                        child: Builder(
                          builder: (context) {
                            return LiteRefScope(
                              onlyOverrides: true,
                              child: Builder(
                                builder: (context) {
                                  final val2 = resourceRef(context, 0);
                                  expect(val2.disposed, false);
                                  return Text('${val2.disposed}');
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('false'), findsOneWidget);
    });

    testWidgets(
      'LiteRefScope should fetch from the parent scope when the '
      'closest scope is marked as onlyOverrides',
      (tester) async {
        final resourceRef = Ref.scopedFamily((ctx, int f) => _Resource());

        await tester.pumpWidget(
          MaterialApp(
            home: LiteRefScope(
              child: Builder(
                builder: (context) {
                  final val = resourceRef(context, 0);
                  expect(val.disposed, false);
                  val.disposed = true;
                  return LiteRefScope(
                    onlyOverrides: true,
                    child: Builder(
                      builder: (context) {
                        final val = resourceRef(context, 0);
                        expect(val.disposed, true);
                        return Text('${val.disposed}');
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('true'), findsOneWidget);
      },
    );
  });
}

class _Controller {
  _Controller({required this.id, this.value = 0});

  final int id;
  int value;
}

class _Resource implements Disposable {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
  }
}
