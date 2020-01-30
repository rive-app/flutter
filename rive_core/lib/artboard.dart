import 'component.dart';
import 'dependency_sorter.dart';
import 'src/generated/artboard_base.dart';
export 'src/generated/artboard_base.dart';

abstract class ArtboardDelegate {
  void markBoundsDirty();
}

class _ArtboardDirt {
  static const int components = 1 << 0;
  static const int drawOrder = 1 << 1;
}

class Artboard extends ArtboardBase {
  ArtboardDelegate _delegate;
  List<Component> _dependencyOrder = [];

  int _dirtDepth = 0;
  int _dirt = 255;

  @override
  Artboard get artboard => this;

  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is ArtboardDelegate) {
      _delegate = to;
    }
  }

  @override
  void widthChanged(double from, double to) {
    super.widthChanged(from, to);
    _delegate?.markBoundsDirty();
  }

  @override
  void heightChanged(double from, double to) {
    super.heightChanged(from, to);
    _delegate?.markBoundsDirty();
  }

  @override
  void xChanged(double from, double to) {
    super.xChanged(from, to);
    _delegate?.markBoundsDirty();
  }

  @override
  void yChanged(double from, double to) {
    super.yChanged(from, to);
    _delegate?.markBoundsDirty();
  }

  void onComponentDirty(Component component) {
    if ((dirt & _ArtboardDirt.components) == 0) {
      context?.markNeedsAdvance();
      _dirt |= _ArtboardDirt.components;
    }

    /// If the order of the component is less than the current dirt depth,
    /// update the dirt depth so that the update loop can break out early and
    /// re-run (something up the tree is dirty).
    if (component.graphOrder < _dirtDepth) {
      _dirtDepth = component.graphOrder;
    }
  }

  /// Sort the DAG for resolution in order of dependencies such that dependent
  /// compnents process after their dependencies.
  void sortDependencies() {
    var optimistic = DependencySorter();
    var order = optimistic.sort(this);
    if (order == null) {
      // cycle detected, use a more robust solver
      var robust = TarjansDependencySorter();
      order = robust.sort(this);
    }
    _dependencyOrder = order;
    for (final component in _dependencyOrder) {
      component.graphOrder = graphOrder++;
      component.dirt = 255;
    }

    _dirt |= _ArtboardDirt.components;
  }

  /// Update any dirty components in this artboard.
  bool advance(double elapsedSeconds) {
    if ((_dirt & _ArtboardDirt.components) != 0) {
      const int maxSteps = 100;
      int step = 0;
      int count = _dependencyOrder.length;
      while ((_dirt & _ArtboardDirt.components) != 0 && step < maxSteps) {
        _dirt &= ~_ArtboardDirt.components;
        // Track dirt depth here so that if something else marks
        // dirty, we restart.
        for (int i = 0; i < count; i++) {
          Component component = _dependencyOrder[i];
          _dirtDepth = i;
          int d = component.dirt;
          if (d == 0) {
            continue;
          }
          component.dirt = 0;
          component.update(d);
          if (_dirtDepth < i) {
            break;
          }
        }
        step++;
      }
      return true;
    }
    return false;
  }

  @override
  void update(int dirt) {}

  @override
  bool resolveArtboard() => true;
}
