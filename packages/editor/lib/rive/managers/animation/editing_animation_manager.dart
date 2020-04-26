import 'dart:async';

import 'package:core/core.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/managers/animation/animation_time_manager.dart';
import 'package:rxdart/rxdart.dart';

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
      List<KeyedViewModel> children = [];
      for (final keyedProperty in keyedObject.keyedProperties) {
        children.add(
          KeyedPropertyViewModel(
            keyedProperty: keyedProperty,
            label: 'Property',
          ),
        );
      }
      hierarchy.add(
        KeyedObjectViewModel(
          keyedObject: keyedObject,
          component: core.resolve(keyedObject.objectId),
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
abstract class KeyedViewModel {
  List<KeyedViewModel> get children;
}

/// Represents a Core object's KeyedObject in the hierarchy.
class KeyedObjectViewModel extends KeyedViewModel {
  final KeyedObject keyedObject;
  final Component component;

  @override
  final List<KeyedViewModel> children;

  KeyedObjectViewModel({
    this.keyedObject,
    this.component,
    this.children,
  });
}

/// An ephemeral group that has no backing core properties, just a logical
/// grouping of sub keyed objects.
class KeyedGroupViewModel extends KeyedViewModel {
  final String label;

  @override
  final List<KeyedViewModel> children;

  KeyedGroupViewModel({
    this.label,
    this.children,
  });
}

/// A leaf in the animation hierarchy tree, a property with real keyframes.
class KeyedPropertyViewModel extends KeyedViewModel {
  final KeyedProperty keyedProperty;
  final String label;
  final String subLabel;

  @override
  List<KeyedViewModel> get children => null;

  KeyedPropertyViewModel({
    this.keyedProperty,
    this.label,
    this.subLabel,
  });
}
