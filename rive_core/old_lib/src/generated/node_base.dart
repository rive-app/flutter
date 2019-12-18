/// Core automatically generated lib/src/generated/node_base.dart.
/// Do not modify manually.

import '../../container_component.dart';

abstract class NodeBase extends ContainerComponent {
  double _x;
  double get x => _x;
  set x(double value) {
    if (_x == value) {
      return;
    }
    double from = _x;
    _x = value;
    _xChanged(from, value);
  }

  void _xChanged(double from, double to) {}
  double _y;
  double get y => _y;
  set y(double value) {
    if (_y == value) {
      return;
    }
    double from = _y;
    _y = value;
    _yChanged(from, value);
  }

  void _yChanged(double from, double to) {}
  double _rotation;
  double get rotation => _rotation;
  set rotation(double value) {
    if (_rotation == value) {
      return;
    }
    double from = _rotation;
    _rotation = value;
    _rotationChanged(from, value);
  }

  void _rotationChanged(double from, double to) {}
  double _scaleX;
  double get scaleX => _scaleX;
  set scaleX(double value) {
    if (_scaleX == value) {
      return;
    }
    double from = _scaleX;
    _scaleX = value;
    _scaleXChanged(from, value);
  }

  void _scaleXChanged(double from, double to) {}
  double _scaleY;
  double get scaleY => _scaleY;
  set scaleY(double value) {
    if (_scaleY == value) {
      return;
    }
    double from = _scaleY;
    _scaleY = value;
    _scaleYChanged(from, value);
  }

  void _scaleYChanged(double from, double to) {}
  double _opacity;
  double get opacity => _opacity;
  set opacity(double value) {
    if (_opacity == value) {
      return;
    }
    double from = _opacity;
    _opacity = value;
    _opacityChanged(from, value);
  }

  void _opacityChanged(double from, double to) {}
}
