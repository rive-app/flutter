import 'dart:collection';

import 'package:graphs/graphs.dart';

import 'component.dart';

class DependencySorter {
  HashSet<Component> _perm;
  HashSet<Component> _temp;
  List<Component> _order;

  DependencySorter() {
    _perm = HashSet<Component>();
    _temp = HashSet<Component>();
  }

  List<Component> sort(Component root) {
    _order = <Component>[];
    if (!visit(root)) {
      return null;
    }
    return _order;
  }

  bool visit(Component n) {
    if (_perm.contains(n)) {
      return true;
    }
    if (_temp.contains(n)) {
      // cycle detected!
      return false;
    }

    _temp.add(n);

    Set<Component> dependents = n.dependents;
    if (dependents != null) {
      for (final Component d in dependents) {
        if (!visit(d)) {
          return false;
        }
      }
    }
    _perm.add(n);
    _order.insert(0, n);

    return true;
  }
}

/// Sorts dependencies for Actors even when cycles are present
///
/// Any nodes that form part of a cycle can be found in `cycleNodes` after
/// `sort`. NOTE: Nodes isolated by cycles will not be found in `_order` or
/// `cycleNodes` e.g. `A -> B <-> C -> D` isolates D when running a sort based
/// on A
class TarjansDependencySorter extends DependencySorter {
  HashSet<Component> _cycleNodes;
  TarjansDependencySorter() {
    _perm = HashSet<Component>();
    _temp = HashSet<Component>();
    _cycleNodes = HashSet<Component>();
  }

  HashSet<Component> get cycleNodes => _cycleNodes;

  @override
  List<Component> sort(Component root) {
    _order = <Component>[];

    if (!visit(root)) {
      // if we detect cycles, go find them all
      _perm.clear();
      _temp.clear();
      _cycleNodes.clear();
      _order.clear();

      var cycles = stronglyConnectedComponents<Component>(
          [root], (Component node) => node.dependents);

      cycles.forEach((cycle) {
        // cycles of len 1 are not cycles.
        if (cycle.length > 1) {
          cycle.forEach((cycleMember) {
            _cycleNodes.add(cycleMember);
          });
        }
      });

      // revisit the tree, skipping nodes on any cycle.
      visit(root);
    }

    return _order;
  }

  @override
  bool visit(Component n) {
    if (cycleNodes.contains(n)) {
      // skip any nodes on a known cycle.
      return true;
    }

    return super.visit(n);
  }
}
