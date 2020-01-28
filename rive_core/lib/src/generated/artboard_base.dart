/// Core automatically generated lib/src/generated/artboard_base.dart.
/// Do not modify manually.

import 'package:core/core.dart';
import 'package:flutter/material.dart';
import '../../container_component.dart';

abstract class ArtboardBase extends ContainerComponent {
  static const int typeKey = 1;
  @override
  int get coreType => ArtboardBase.typeKey;

  /// --------------------------------------------------------------------------
  /// Width field with key 4.
  double _width;
  static const int widthPropertyKey = 4;

  /// Width of the artboard.
  double get width => _width;

  /// Change the [_width] field value.
  /// [widthChanged] will be invoked only if the field's value has changed.
  set width(double value) {
    if (_width == value) {
      return;
    }
    double from = _width;
    _width = value;
    widthChanged(from, value);
  }

  @mustCallSuper
  void widthChanged(double from, double to) {
    context?.changeProperty(this, widthPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Height field with key 5.
  double _height;
  static const int heightPropertyKey = 5;

  /// Height of the artboard.
  double get height => _height;

  /// Change the [_height] field value.
  /// [heightChanged] will be invoked only if the field's value has changed.
  set height(double value) {
    if (_height == value) {
      return;
    }
    double from = _height;
    _height = value;
    heightChanged(from, value);
  }

  @mustCallSuper
  void heightChanged(double from, double to) {
    context?.changeProperty(this, heightPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// X field with key 6.
  double _x;
  static const int xPropertyKey = 6;

  /// X coordinate in editor world space.
  double get x => _x;

  /// Change the [_x] field value.
  /// [xChanged] will be invoked only if the field's value has changed.
  set x(double value) {
    if (_x == value) {
      return;
    }
    double from = _x;
    _x = value;
    xChanged(from, value);
  }

  @mustCallSuper
  void xChanged(double from, double to) {
    context?.changeProperty(this, xPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// Y field with key 7.
  double _y;
  static const int yPropertyKey = 7;

  /// Y coordinate in editor world space.
  double get y => _y;

  /// Change the [_y] field value.
  /// [yChanged] will be invoked only if the field's value has changed.
  set y(double value) {
    if (_y == value) {
      return;
    }
    double from = _y;
    _y = value;
    yChanged(from, value);
  }

  @mustCallSuper
  void yChanged(double from, double to) {
    context?.changeProperty(this, yPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// OriginX field with key 8.
  double _originX;
  static const int originXPropertyKey = 8;

  /// Origin x in normalized coordinates (0 = center, -1 = left, 1 = right).
  double get originX => _originX;

  /// Change the [_originX] field value.
  /// [originXChanged] will be invoked only if the field's value has changed.
  set originX(double value) {
    if (_originX == value) {
      return;
    }
    double from = _originX;
    _originX = value;
    originXChanged(from, value);
  }

  @mustCallSuper
  void originXChanged(double from, double to) {
    context?.changeProperty(this, originXPropertyKey, from, to);
  }

  /// --------------------------------------------------------------------------
  /// OriginY field with key 9.
  double _originY;
  static const int originYPropertyKey = 9;

  /// Origin y in normalized coordinates (0 = center, -1 = left, 1 = right).
  double get originY => _originY;

  /// Change the [_originY] field value.
  /// [originYChanged] will be invoked only if the field's value has changed.
  set originY(double value) {
    if (_originY == value) {
      return;
    }
    double from = _originY;
    _originY = value;
    originYChanged(from, value);
  }

  @mustCallSuper
  void originYChanged(double from, double to) {
    context?.changeProperty(this, originYPropertyKey, from, to);
  }

  @override
  void changeNonNull([PropertyChanger changer]) {
    changer ??= context?.changeProperty;
    super.changeNonNull(changer);
    if (width != null) {
      context?.changeProperty(this, widthPropertyKey, width, width);
    }
    if (height != null) {
      context?.changeProperty(this, heightPropertyKey, height, height);
    }
    if (x != null) {
      context?.changeProperty(this, xPropertyKey, x, x);
    }
    if (y != null) {
      context?.changeProperty(this, yPropertyKey, y, y);
    }
    if (originX != null) {
      context?.changeProperty(this, originXPropertyKey, originX, originX);
    }
    if (originY != null) {
      context?.changeProperty(this, originYPropertyKey, originY, originY);
    }
  }
}
