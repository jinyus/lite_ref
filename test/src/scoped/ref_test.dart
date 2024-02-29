import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lite_ref/lite_ref.dart';

void main() {
  test('overriden instance should be equal to main', () {
    final countRef = Ref.scoped((ctx) => 1);
    final countClone = countRef.overrideWith((ctx) => 2);

    expect(countRef, countClone);

    final hashSet = <Object>{}..add(countRef);

    expect(hashSet.contains(countClone), true);
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
              expect(() => countRef(context), throwsArgumentError);
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
}
