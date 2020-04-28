import 'dart:async';
import 'dart:collection';

import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

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

  Stream<Iterable<KeyHierarchyViewModel>> get hierarchy =>
      _hierarchyController.stream;

  EditingAnimationManager(LinearAnimation animation) : super(animation) {
    animation.context.addDelegate(this);
    _updateHierarchy();
  }

  @override
  void dispose() {
    cancelDebounce(_updateHierarchy);
    _hierarchyController.close();
    animation.context.removeDelegate(this);
    super.dispose();
  }

  @override
  void onAutoKey(Component component, int propertyKey) {
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
    _componentViewModels[component] = viewModel = KeyedComponentViewModel(
      component: component,
      keyedObject: keyedObject,
      children: children,
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
      final viewModel = needParenting[i];
      // Make sure that all the parents were included in the timeline, some may
      // not be if they weren't keyed (there'd be no KeyedObject in the file for
      // them).
      var timelineParent = viewModel.component.timelineParent;

      var parent = _componentViewModels[timelineParent];
      parent ??= _makeComponentViewModel(timelineParent);
      if (timelineParent.timelineParent != null) {
        needParenting.add(parent);
      } else {
        hierarchy.add(parent);
      }

      if (parent is KeyedComponentViewModel) {
        var groupName = viewModel.component.timelineParentGroup;
        if (groupName != null) {
          // Find the right one.
          var groups = _componentGroupViewModels[parent.component] ??=
              HashMap<String, KeyedGroupViewModel>();

          var group = groups[groupName];
          // Create the group if we didn't have it.
          if (group == null) {
            Set<KeyHierarchyViewModel> children = {};
            groups[groupName] = group =
                KeyedGroupViewModel(label: groupName, children: children);
          }
          // Make sure parent contains group. It's a set so we can do this.
          parent.children.add(group);
          // Add us to the group.
          group.children.add(viewModel);
        } else {
          parent.children.add(viewModel);
        }
      }
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

/// Represents a Component in the hierarchy that may have a keyedObject if it
/// has keyed properties. It may not have keyed properties if it's just
/// containing other groups/objects that themselves have keyed properties.
@immutable
class KeyedComponentViewModel extends KeyHierarchyViewModel {
  /// There's no guarantee that there will be a keyedObject for this
  /// view model
  final KeyedObject keyedObject;

  /// A component is always present in the viewmodel.
  final Component component;

  @override
  final Set<KeyHierarchyViewModel> children;

  const KeyedComponentViewModel({
    @required this.component,
    this.keyedObject,
    this.children,
  }) : assert(component != null);
}

/// An ephemeral group that has no backing core properties, just a logical
/// grouping of sub keyed objects.
@immutable
class KeyedGroupViewModel extends KeyHierarchyViewModel {
  final String label;

  @override
  final Set<KeyHierarchyViewModel> children;

  const KeyedGroupViewModel({
    this.label,
    this.children,
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
