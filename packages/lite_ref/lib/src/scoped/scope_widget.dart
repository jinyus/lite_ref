part of 'scoped.dart';

typedef _Cache = Map<Object, ScopedRef<dynamic>>;

/// Dependency injection of [ScopedRef]s.
class LiteRefScope extends InheritedWidget {
  /// Create a new [LiteRefScope]
  /// If [onlyOverrides] is true, only overridden
  /// ScopedRefs will be provided to children.
  LiteRefScope({
    required super.child,
    super.key,
    List<ScopedRef<dynamic>>? overrides,
    this.onlyOverrides = false,
  }) : _overrides = overrides?.toSet();

  final Set<ScopedRef<dynamic>>? _overrides;

  /// If true, only overridden ScopedRefs will be provided to children.
  final bool onlyOverrides;

  // coverage:ignore-start
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
  // coverage:ignore-end

  @override
  InheritedElement createElement() => _RefScopeElement(this);

  static _RefScopeElement _of(BuildContext context, Object id) {
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

    // if the element's widget is onlyOverride, we need to check if the id
    // is in the overrides list, if not, we need to visit all ancestors
    // until we find an element with the id or one that is not onlyOverride
    if (refScopeElement.box.onlyOverrides) {
      if (refScopeElement.box._overrides?.contains(id) ?? false) {
        return refScopeElement;
      }

      _RefScopeElement? newElement;

      context.visitAncestorElements((element) {
        if (element is _RefScopeElement) {
          if (!element.box.onlyOverrides) {
            newElement = element;
            return false;
          }
          if (element.box._overrides?.contains(id) ?? false) {
            newElement = element;
            return false;
          }
        }
        return true;
      });

      if (newElement == null) {
        throw Exception(
          'Could not find a LiteRefScope with the'
          ' instance or one that is not marked as onlyOverride',
        );
      }

      return newElement!;
    }

    return refScopeElement;
  }
}

class _RefScopeElement extends InheritedElement {
  _RefScopeElement(LiteRefScope super.widget);

  LiteRefScope get box => widget as LiteRefScope;

  late final _cache = _Cache();

  late final _autoDisposeBindings = <Element, Set<ScopedRef<dynamic>>>{};

  void _addAutoDisposeBinding(Element element, ScopedRef<dynamic> ref) {
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
  void removeDependent(Element dependent) {
    // child has been removed
    final refs = _autoDisposeBindings.remove(dependent);

    // coverage:ignore-start
    if (refs == null) return super.removeDependent(dependent);
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

    super.removeDependent(dependent);
  }

  @override
  void unmount() {
    for (final ref in _cache.values) {
      ref._dispose();
    }
    _cache.clear();
    box._overrides?.clear();
    _autoDisposeBindings.clear();
    super.unmount();
  }
}
