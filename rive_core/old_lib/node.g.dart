// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// CoreTypeGenerator
// **************************************************************************

class Node extends NodeBase {
  double get x => _x;

  set x(double value) {
    if (_x == value) {
      return;
    }
    context?.changeProperty(this, xCoreKey, _x, value, null);
    _x = value;
  }

  double get y => _y;

  set y(double value) {
    if (_y == value) {
      return;
    }
    context?.changeProperty(this, yCoreKey, _y, value, null);
    _y = value;
  }

  double get rotation => _rotation;

  set rotation(double value) {
    if (_rotation == value) {
      return;
    }
    context?.changeProperty(this, rotationCoreKey, _rotation, value, null);
    _rotation = value;
  }

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    print('serializing NodeBase');
    serializer.writeValue('x', _x);
    serializer.writeValue('y', _y);
    serializer.writeValue('rotation', _rotation);
  }
}
