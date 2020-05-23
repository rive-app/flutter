import 'dart:async';
import 'dart:collection';

import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
class KeyComponentsEvent {
  final Iterable<Component> components;
  final int propertyKey;

  const KeyComponentsEvent({
    @required this.components,
    @required this.propertyKey,
  });
}

/// Animation manager for the currently editing [LinearAnimation].
class EditingAnimationManager extends AnimationTimeManager
    with RiveFileDelegate {
  final HashMap<Component, KeyedComponentViewModel> _componentViewModels =
      HashMap<Component, KeyedComponentViewModel>();
  final HashMap<Component, HashMap<String, KeyedGroupViewModel>>
      _componentGroupViewModels =
      HashMap<Component, HashMap<String, KeyedGroupViewModel>>();

  final _hierarchyController =
      BehaviorSubject<Iterable<KeyHierarchyViewModel>>();

  final _keyController = StreamController<KeyComponentsEvent>();

  /// Set a keyframe on a property for a bunch of components.
  Sink<KeyComponentsEvent> get keyComponents => _keyController;

  Stream<Iterable<KeyHierarchyViewModel>> get hierarchy =>
      _hierarchyController.stream;

  final HashSet<_AllPropertiesHelper> _allPropertiesHelpers =
      HashSet<_AllPropertiesHelper>();

  EditingAnimationManager(LinearAnimation animation, OpenFileContext activeFile)
      : super(animation, activeFile) {
    animation.context.addDelegate(this);
    _updateHierarchy();

    _keyController.stream.listen(_keyComponents);
  }

  void _keyComponents(KeyComponentsEvent event) {
    for (final component in event.components) {
      onAutoKey(component, event.propertyKey);
    }
    animation.context.captureJournalEntry();
  }

  @override
  void dispose() {
    for (final allHelper in _allPropertiesHelpers) {
      allHelper.reset();
    }
    cancelDebounce(_updateHierarchy);
    _hierarchyController.close();
    _keyController.close();
    animation.context.removeDelegate(this);
    super.dispose();
  }

  @override
  void onAutoKey(Component component, int propertyKey) {
    /// The stage will switch the active artboard for us, but some of these
    /// operations are debounced so there's a risk onAutoKey will call while
    /// another artboard's animation is still active so we early out here if
    /// autoKey is triggered for a property on an object that is not in the same
    /// artboard as our currently editing animation.
    if (component.artboard != animation.artboard) {
      return;
    }
    var keyFrame = component.addKeyFrame(animation, propertyKey, frame);
    // Set the value of the keyframe.
    keyFrame.valueFrom(component, propertyKey);
  }

  @override
  void onObjectAdded(Core object) {
    switch (object.coreType) {
      case KeyedObjectBase.typeKey:
      case KeyedPropertyBase.typeKey:
        debounce(_updateHierarchy);
        break;
    }
  }

  @override
  void onObjectRemoved(Core object) {
    switch (object.coreType) {
      case KeyedObjectBase.typeKey:
      case KeyedPropertyBase.typeKey:
        debounce(_updateHierarchy);
        break;
    }
  }

  KeyedComponentViewModel _makeComponentViewModel(Component component,
      {KeyedObject keyedObject}) {
    KeyedComponentViewModel viewModel;
    Set<KeyHierarchyViewModel> children = {};
    final allProperties = _AllPropertiesHelper(animation);
    _allPropertiesHelpers.add(allProperties);
    _componentViewModels[component] = viewModel = KeyedComponentViewModel(
      component: component,
      keyedObject: keyedObject,
      children: children,
      allProperties: allProperties,
    );
    return viewModel;
  }

  void _updateHierarchy() {
    var keyedObjects = animation.keyedObjects;
    var core = animation.context;

    // Reset children.
    for (final vm in _componentViewModels.values) {
      vm.children.clear();
      // Clear component groups.
      var groups = _componentGroupViewModels[vm.component];
      if (groups != null) {
        for (final group in groups.values) {
          group.children.clear();
        }
      }
    }

    // Reset helpers.
    for (final allHelper in _allPropertiesHelpers) {
      allHelper.reset();
    }

    // First pass, build all viewmodels for keyed objects and properties, no
    // parenting yet but track which ones need to be.
    Set<KeyHierarchyViewModel> hierarchy = {};
    List<KeyedComponentViewModel> needParenting = [];
    for (final keyedObject in keyedObjects) {
      Component component = core.resolve(keyedObject.objectId);

      var viewModel = _componentViewModels[component];
      if (viewModel == null) {
        _componentViewModels[component] = viewModel =
            _makeComponentViewModel(component, keyedObject: keyedObject);
      }

      // Build up a list of the properties that we can sort and then build into
      // viewmodels.
      var keyedProperties = keyedObject.keyedProperties;
      List<_KeyedPropertyHelper> properties =
          List<_KeyedPropertyHelper>(keyedProperties.length);
      int index = 0;
      for (final keyedProperty in keyedObject.keyedProperties) {
        properties[index++] = _KeyedPropertyHelper(
          keyedProperty: keyedProperty,
          // Properties that have the same group key will be grouped together
          // after ordering.
          groupKey: RiveCoreContext.propertyKeyGroupHashCode(
              keyedProperty.propertyKey),
          // For now use the propertyKey as the order value, if we find we
          // want to customize this further, the core generator will need to
          // provide a custom sort value that can be specified in the
          // definition files.
          propertyOrder: keyedProperty.propertyKey,
        );
      }
      // Do the first (arguably heavier as we should have less grouped
      // properties) with regular (unstable) sort.
      properties.sort((a, b) => a.propertyOrder.compareTo(b.propertyOrder));
      // Then use a stable sort to sort by group.
      mergeSort<_KeyedPropertyHelper>(properties,
          compare: (a, b) => a.groupKey.compareTo(b.groupKey));

      // Finally we can build up the children.
      int lastGroupKey = 0;
      for (final property in properties) {
        String groupLabel;
        if (property.groupKey != 0) {
          groupLabel = property.groupKey == lastGroupKey
              // Previous property had the same group key, so let's just use an
              // empty label.
              ? ''
              // Mark the label...
              : RiveCoreContext.propertyKeyGroupName(
                  property.keyedProperty.propertyKey);
        }

        viewModel.children.add(
          KeyedPropertyViewModel(
            keyedProperty: property.keyedProperty,
            label: groupLabel ??
                RiveCoreContext.propertyKeyName(
                    property.keyedProperty.propertyKey),
            subLabel: groupLabel != null
                ? RiveCoreContext.propertyKeyName(
                    property.keyedProperty.propertyKey)
                : null,
            component: component,
          ),
        );

        // Also add it to the keyed properties, this is the first step in
        // building up the all properties.
        viewModel.allProperties.add(property.keyedProperty);

        lastGroupKey = property.groupKey;
      }

      if (component.timelineParent == null) {
        hierarchy.add(viewModel);
      } else {
        needParenting.add(viewModel);
      }
    }

    // Now iterate the ones that need parenting. For loop as we might alter the
    // collection.
    for (int i = 0; i < needParenting.length; i++) {
      // This will always be a ComponentViewModel.
      final viewModel = needParenting[i];
      var allProps = viewModel.allProperties;

      // Make sure that all the parents were included in the timeline, some may
      // not be if they weren't keyed (there'd be no KeyedObject in the file for
      // them).
      var timelineParent = viewModel.component.timelineParent;

      var parent = _componentViewModels[timelineParent];
      parent ??= _makeComponentViewModel(timelineParent);

      // Aggregate the all properties...
      parent.allProperties.merge(allProps);

      if (timelineParent.timelineParent != null) {
        needParenting.add(parent);
      } else {
        hierarchy.add(parent);
      }

      // if (parent is KeyedComponentViewModel) {
      var groupName = viewModel.component.timelineParentGroup;
      if (groupName != null) {
        // Find the right one.
        var groups = _componentGroupViewModels[parent.component] ??=
            HashMap<String, KeyedGroupViewModel>();

        var group = groups[groupName];
        // Create the group if we didn't have it.
        if (group == null) {
          Set<KeyHierarchyViewModel> children = {};
          final allProperties = _AllPropertiesHelper(animation);
          _allPropertiesHelpers.add(allProperties);
          groups[groupName] = group = KeyedGroupViewModel(
            label: groupName,
            children: children,
            allProperties: allProperties,
          );
        }
        // Make sure all properties from the component get inserted into the
        // group.
        parent.allProperties.merge(allProps);
        group.allProperties.merge(allProps);
        // Keep pushing them up the tree (could later change this to be
        // recursive).
        if (parent.component.timelineParent != null) {
          var propagate = parent.component;
          while (propagate.timelineParent != null) {
            var parentViewModel =
                _componentViewModels[propagate.timelineParent];
            if (parentViewModel == null) {
              break;
            }
            parentViewModel.allProperties.merge(allProps);
            var groupName = propagate.timelineParentGroup;
            if (groupName != null) {
              var groups = _componentGroupViewModels[parentViewModel.component];
              if (groups != null) {
                var group = groups[groupName];
                if (group != null) {
                  group.allProperties.merge(allProps);
                }
              }
            }
            propagate = parentViewModel.component;
          }
        }

        // Make sure parent contains group. It's a set so we can do this.
        parent.children.add(group);
        // Add us to the group.
        group.children.add(viewModel);
      } else {
        parent.children.add(viewModel);
      }
      // }
    }

    _hierarchyController.add(hierarchy.toList(growable: false));
  }
}

/// Base class for a node with children in the hierarchy. This can be either a
/// keyed object or a named group (like Strokes is a named group within a
/// KeyedObject with more KeyedObjects within it).
@immutable
abstract class KeyHierarchyViewModel {
  Set<KeyHierarchyViewModel> get children;
  const KeyHierarchyViewModel();
}

/// Base class for a KeyedViewModel with all keys.
@immutable
abstract class AllKeysViewModel extends KeyHierarchyViewModel {
  _AllPropertiesHelper get allProperties;
  const AllKeysViewModel();
}

/// Represents a Component in the hierarchy that may have a keyedObject if it
/// has keyed properties. It may not have keyed properties if it's just
/// containing other groups/objects that themselves have keyed properties.
@immutable
class KeyedComponentViewModel extends AllKeysViewModel {
  /// There's no guarantee that there will be a keyedObject for this
  /// view model
  final KeyedObject keyedObject;

  /// A component is always present in the viewmodel.
  final Component component;

  @override
  final Set<KeyHierarchyViewModel> children;

  /// All keyed properties within this viewmodel.
  @override
  final _AllPropertiesHelper allProperties;

  const KeyedComponentViewModel({
    @required this.component,
    this.keyedObject,
    this.children,
    this.allProperties,
  }) : assert(component != null);
}

/// An ephemeral group that has no backing core properties, just a logical
/// grouping of sub keyed objects. N.B. that a group is never multi-nested, a
/// KeyedGroupViewModel's children will always be KeyedComponentViewModel but we
/// conform to KeyHierarchyViewModel to fit the class hierarchy/override for
/// children.
@immutable
class KeyedGroupViewModel extends AllKeysViewModel {
  final String label;

  /// All keyed properties within this viewmodel.
  @override
  final _AllPropertiesHelper allProperties;

  @override
  final Set<KeyHierarchyViewModel> children;

  const KeyedGroupViewModel({
    this.label,
    this.children,
    this.allProperties,
  });
}

/// A leaf in the animation hierarchy tree, a property with real keyframes.
@immutable
class KeyedPropertyViewModel extends KeyHierarchyViewModel {
  final KeyedProperty keyedProperty;
  final String label;
  final String subLabel;
  final Component component;

  @override
  Set<KeyHierarchyViewModel> get children => null;

  const KeyedPropertyViewModel({
    this.keyedProperty,
    this.label,
    this.subLabel,
    this.component,
  });
}

/// Helper used to sort keyed properties.
class _KeyedPropertyHelper {
  final int groupKey;
  final int propertyOrder;
  final KeyedProperty keyedProperty;

  _KeyedPropertyHelper({
    this.groupKey,
    this.keyedProperty,
    this.propertyOrder,
  });
}

class AllKeyFrame implements KeyFrameInterface {
  final HashSet<KeyFrame> keyframes = HashSet<KeyFrame>();

  @override
  final int frame;

  AllKeyFrame(this.frame);
}

class _AllPropertiesHelper {
  final LinearAnimation animation;
  final HashSet<KeyedProperty> _all = HashSet<KeyedProperty>();
  final HashSet<KeyedObject> _objects = HashSet<KeyedObject>();
  KeyFrameList<AllKeyFrame> _cached;

  _AllPropertiesHelper(this.animation);

  /// Lazily rebuild the frames list when requested.
  KeyFrameList<AllKeyFrame> get cached {
    if (_cached != null) {
      return _cached;
    }

    HashMap<int, AllKeyFrame> lut = HashMap<int, AllKeyFrame>();
    // Merge the frames.
    for (final keyedProperty in _all) {
      for (final keyframe in keyedProperty.keyframes) {
        var allKey = lut[keyframe.frame];
        if (allKey == null) {
          lut[keyframe.frame] = allKey = AllKeyFrame(keyframe.frame);
        }
        allKey.keyframes.add(keyframe);
      }
    }
    _cached = KeyFrameList<AllKeyFrame>();
    _cached.keyframes = lut.values;
    _cached.sort();
    return _cached;
  }

  void add(KeyedProperty property) {
    _all.add(property);
    var ko = property.keyedObject;
    if (_objects.add(ko)) {
      ko.keyframesMoved.addListener(_markDirty);
      // Kind of a hack just to listen to the animation too, but only when we
      // actually have a keyframe.
      if (_objects.length == 1) {
        animation.keyframesChanged.addListener(_markDirty);
      }
    }
  }

  void merge(_AllPropertiesHelper allHelper) {
    allHelper._all.forEach(add);
  }

  void reset() {
    animation.keyframesChanged.removeListener(_markDirty);
    for (final object in _objects) {
      object.keyframesMoved.removeListener(_markDirty);
    }
    _objects.clear();
    _all.clear();
    _markDirty();
  }

  void _markDirty() {
    _cached = null;
  }
}
