import 'package:basic_interfaces/basic_interfaces.dart';
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
      final resource = Resource();
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
}

class Resource implements Disposable {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
  }
}
