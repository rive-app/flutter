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

  List<ConversionFinalizer> _finalizers;
  List<ConversionFinalizer> get finalizers => _finalizers;

  void addFinalizer(ConversionFinalizer cf) {
    _finalizers ??= <ConversionFinalizer>[];
    _finalizers.add(cf);
  }

  @mustCallSuper
  void deserialize(Map<String, Object> jsonData) {
    final name = jsonData['name'];

    // print('Component ${_component.runtimeType} "$name"');
    if (name is String) {
      _component.name = name;
    }
  }
}

abstract class ConversionFinalizer {
  const ConversionFinalizer(this.component);

  final Component component;

  RiveFile get riveFile {
    final riveFile = component.context;
    assert(riveFile != null);
    return riveFile;
  }

  void finalize(Map<String, Component> fileComponents);
}
