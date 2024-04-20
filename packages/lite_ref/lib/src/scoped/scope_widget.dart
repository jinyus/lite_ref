part of 'scoped.dart';

typedef _Cache = Map<Object, ScopedObject<dynamic>>;

/// Dependency injection of [ScopedRef]s.
class LiteRefScope extends InheritedWidget {
  /// Create a new [LiteRefScope]
  /// If [onlyOverrides] is true, only overridden
  /// ScopedRefs will be provided to children.
  ///
  /// If [onlyOverrides] is true, only overridden
  /// ScopedRefs will be provided to children.
  const LiteRefScope({
    required super.child,
    super.key,
    this.overrides,
    this.onlyOverrides = false,
  });

  /// List of ScopedRefs to override.
  final Set<IScopedRef<dynamic>>? overrides;

  /// If true, only overridden ScopedRefs will be provided to children.
  final bool onlyOverrides;

  // coverage:ignore-start
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
  // coverage:ignore-end

  @override
  InheritedElement createElement() => _RefScopeElement(this);

  static _RefScopeElement _of(BuildContext context, IScopedRef<dynamic> ref) {
    final element =
        context.getElementForInheritedWidgetOfExactType<LiteRefScope>();

    assert(
      element != null,
      '''
  You must wrap your app with a `LiteRefScope`.

  runApp(
    LiteRefScope(
      child: MyApp(),
    ),
  );
  ''',
    );

    final refScopeElement = element! as _RefScopeElement;

    // if the element's widget is onlyOverride, we need to check if the ref
    // is in the overrides list, if not, we need to visit all ancestors
    // until we find an element with the ref or one that is not onlyOverride
    if (refScopeElement.scope.onlyOverrides) {
      if (refScopeElement.scope.overrides?.contains(ref) ?? false) {
        return refScopeElement;
      }

      var parentElement = refScopeElement._parent;

      while (parentElement != null) {
        if (!parentElement.scope.onlyOverrides) break;

        if (parentElement.scope.overrides?.contains(ref) ?? false) {
          break;
        }

        parentElement = parentElement._parent;
      }

      if (parentElement == null) {
        throw Exception(
          'Could not find a LiteRefScope with "${ref.runtimeType}" '
          'or one that is not marked as onlyOverride. '
          'Please note that "onlyOverride" must be false '
          'for the root LiteRefScope',
        );
      }

      return parentElement;
    }

    return refScopeElement;
  }
}

class _RefScopeElement extends InheritedElement {
  _RefScopeElement(LiteRefScope super.widget);

  _RefScopeElement? _parent;

  LiteRefScope get scope => widget as LiteRefScope;

  late final _cache = _Cache();

  late final _autoDisposeBindings = <Element, Set<ScopedObject<dynamic>>>{};

  late final _oldRefs = <ScopedObject<dynamic>>[];

  void _addAutoDisposeBinding(Element element, ScopedObject<dynamic> ref) {
    final existing = _autoDisposeBindings[element];

    if (existing != null) {
      final added = existing.add(ref);
      if (added) ref._watchCount++;
    } else {
      ref._watchCount++;
      // make this child widget depend on this element
      // so we get notified when it is deactivated
      element.dependOnInheritedElement(this);
      _autoDisposeBindings[element] = {ref};
    }
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    _parent = parent?.getElementForInheritedWidgetOfExactType<LiteRefScope>()
        as _RefScopeElement?;
    super.mount(parent, newSlot);
  }

  @override
  void deactivate() {
    // if this widget gets replaced by another LiteRefScope
    // (eg: hot-reload when it or one of its ancestors has a UniqueKey).
    // We need to store a copy of all Refs in our cache so we don't dispose
    // refs being used by its replacement.
    _oldRefs.addAll(_cache.values.map((e) => e._copy()));
    super.deactivate();
  }

// coverage:ignore-start
  @override
  void activate() {
    super.activate();
    _oldRefs.clear();
  }
// coverage:ignore-end

  @override
  void removeDependent(Element dependent) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (dependent.mounted) return;
      // child has been removed
      final refs = _autoDisposeBindings.remove(dependent);

      // coverage:ignore-start
      if (refs == null) return;
      // coverage:ignore-end

      for (final ref in refs) {
        if (ref.autoDispose) {
          ref._watchCount--;
          if (ref._watchCount < 1) {
            ref._dispose();
            _cache.remove(ref._id);
          }
        }
      }
    });

    super.removeDependent(dependent);
  }

  @override
  void unmount() {
    // this shouldn't be necessary but it's harmless
    // we should be able to just use _oldRefs.
    final toBeDisposed = _oldRefs.isEmpty ? _cache.values : _oldRefs;

    for (final ref in toBeDisposed) {
      ref._dispose();
    }

    _cache.clear();
    _oldRefs.clear();
    _autoDisposeBindings.clear();
    _parent = null;
    super.unmount();
  }
}
