import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';

abstract class ComponentConverter {
  ComponentConverter(
    this._component,
    RiveFile context,
    ContainerComponent maybeParent,
  ) {
    context.batchAdd(() {
      context.addObject(_component);
      maybeParent?.appendChild(_component);
    });
  }

  ComponentConverter.init(this._component);

  final Component _component;
  Component get component => _component;
  // RiveCoreContext context;

  @mustCallSuper
  void deserialize(Map<String, Object> jsonData) {
    final name = jsonData['name'];
    // final parentId = jsonData['parent'];

    print('Component ${_component.runtimeType} "$name"');
    if (name is String) {
      _component.name = name;
    }

    // if (parentId is int) {
    //   component.parentId = parentId;
    // }
  }
}
