part of 'scoped.dart';

typedef _Cache = Map<Object, ScopedRef<dynamic>>;

/// Dependency injection of [ScopedRef]s.
class LiteRefScope extends InheritedWidget {
  /// Create a new [LiteRefScope]
  LiteRefScope({
    required super.child,
    super.key,
    List<ScopedRef<dynamic>>? overrides,
  }) : _overrides = overrides?.toSet();

  /// The [ScopedRef]s that are overridden by this [LiteRefScope].
  final Set<ScopedRef<dynamic>>? _overrides;
  late final _cache = _Cache();

  // coverage:ignore-start
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
  // coverage:ignore-end

  @override
  InheritedElement createElement() => _Element(this);

  static LiteRefScope? _maybeOf(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<LiteRefScope>();
    return element is _Element ? element.box : null;
  }

  static Never _notFound() {
    throw ArgumentError(
      '''
  You must wrap your app with a `LiteRefScope`.

  runApp(
    LiteRefScope(
      child: MyApp(),
    ),
  );
  ''',
    );
  }

  static LiteRefScope _of(BuildContext context) =>
      _maybeOf(context) ?? _notFound();
}

class _Element extends InheritedElement {
  _Element(LiteRefScope super.widget);

  LiteRefScope get box => widget as LiteRefScope;

  @override
  void unmount() {
    for (final ref in box._cache.values) {
      ref._dispose();
    }
    box._cache.clear();
    box._overrides?.clear();
    super.unmount();
  }
}
