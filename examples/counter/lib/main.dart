import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lite_ref/lite_ref.dart';
import 'package:state_beacon/state_beacon.dart';

class Controller {
  Controller({required this.id});

  final int id;

  String get name => 'counter $id';
  late final _count = Beacon.writable(0);

  // we expose it as a readable beacon
  // so it cannot be changed from outside the controller.
  ReadableBeacon<int> get count => _count;

  void increment() => _count.value++;

  void decrement() => _count.value--;

  void dispose() {
    _count.dispose();
  }
}

final countersRef = Ref.scoped((context) => Beacon.writable([0]));

final countControllerRef = Ref.scopedFamily(
  (ctx, int id) => Controller(id: id),
  dispose: (controller) => controller.dispose(),
);

void main() {
  runApp(const LiteRefScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Lite Ref and State Beacon Counter'),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(child: Counters()),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            final counters = countersRef.read(context);
            counters.value = [
              ...counters.value,
              counters.value.fold(0, math.max) + 1,
            ];
          },
          child: const Icon(Icons.add_circle_outline),
        ),
      ),
    );
  }
}

class Counters extends StatelessWidget {
  const Counters({super.key});

  @override
  Widget build(BuildContext context) {
    final counters = countersRef.of(context).watch(context);

    return ListView.builder(
      itemCount: counters.length,
      itemBuilder: (context, index) {
        final id = counters[index];
        return CounterCard(id: id);
      },
    );
  }
}

class CounterCard extends StatelessWidget {
  const CounterCard({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) {
    final controller = countControllerRef.of(context, id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                CounterText(id: id),
                const SizedBox(height: 8),
                CounterButtons(id: id),
              ],
            ),
            PositionedDirectional(
              top: 0,
              end: 0,
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  final counters = countersRef.read(context);
                  counters.value =
                      counters.value.where((e) => e != id).toList();
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CounterText extends StatelessWidget {
  const CounterText({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) {
    final controller = countControllerRef.of(context, id);
    final count = controller.count.watch(context);
    final theme = Theme.of(context);
    return Text('$count', style: theme.textTheme.displayLarge);
  }
}

class CounterButtons extends StatelessWidget {
  const CounterButtons({required this.id, super.key});

  final int id;

  @override
  Widget build(BuildContext context) {
    final controller = countControllerRef.of(context, id);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton(
          onPressed: controller.increment,
          child: const Icon(Icons.add),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: controller.decrement,
          child: const Icon(Icons.remove),
        ),
      ],
    );
  }
}
