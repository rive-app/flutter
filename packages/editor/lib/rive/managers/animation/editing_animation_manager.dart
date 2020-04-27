import 'dart:async';

import 'package:core/core.dart';
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
  final _hierarchyController = BehaviorSubject<Iterable<KeyedViewModel>>();

  Stream<Iterable<KeyedViewModel>> get hierarchy => _hierarchyController.stream;

  EditingAnimationManager(LinearAnimation animation) : super(animation) {
    animation.context.addDelegate(this);
    _updateHierarchy();
  }

  @override
  void dispose() {
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
        _updateHierarchy();
        break;
    }
  }

  @override
  void onObjectRemoved(Core object) {
    switch (object.coreType) {
      case KeyedObjectBase.typeKey:
      case KeyedPropertyBase.typeKey:
        _updateHierarchy();
        break;
    }
  }

  void _updateHierarchy() {
    var keyedObjects = animation.keyedObjects;
    var core = animation.context;
    List<KeyedViewModel> hierarchy = [];
    for (final keyedObject in keyedObjects) {
      Component component = core.resolve(keyedObject.objectId);
      List<KeyedViewModel> children = [];

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

        children.add(
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

      hierarchy.add(
        KeyedObjectViewModel(
          keyedObject: keyedObject,
          component: component,
          children: children,
        ),
      );
    }
    _hierarchyController.add(hierarchy);
  }
}

/// Base class for a node with children in the hierarchy. This can be either a
/// keyed object or a named group (like Strokes is a named group within a
/// KeyedObject with more KeyedObjects within it).
@immutable
abstract class KeyedViewModel {
  List<KeyedViewModel> get children;
  const KeyedViewModel();
}

/// Represents a Core object's KeyedObject in the hierarchy.
@immutable
class KeyedObjectViewModel extends KeyedViewModel {
  final KeyedObject keyedObject;
  final Component component;

  @override
  final List<KeyedViewModel> children;

  const KeyedObjectViewModel({
    this.keyedObject,
    this.component,
    this.children,
  });
}

/// An ephemeral group that has no backing core properties, just a logical
/// grouping of sub keyed objects.
@immutable
class KeyedGroupViewModel extends KeyedViewModel {
  final String label;

  @override
  final List<KeyedViewModel> children;

  const KeyedGroupViewModel({
    this.label,
    this.children,
  });
}

/// A leaf in the animation hierarchy tree, a property with real keyframes.
@immutable
class KeyedPropertyViewModel extends KeyedViewModel {
  final KeyedProperty keyedProperty;
  final String label;
  final String subLabel;
  final Component component;

  @override
  List<KeyedViewModel> get children => null;

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
