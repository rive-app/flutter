/// Core automatically generated lib/src/generated/artboard_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class ArtboardBase extends ContainerComponent {
  static const int typeKey = 1;
  @override
  int get coreType => ArtboardBase.typeKey;
  @override
  Set<int> get coreTypes => {
        ArtboardBase.typeKey,
        ContainerComponentBase.typeKey,
        ComponentBase.typeKey
      };

  /// --------------------------------------------------------------------------
  /// Width field with key 7.
  double _width;
  static const int widthPropertyKey = 7;

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
    onPropertyChanged(widthPropertyKey, from, value);
    widthChanged(from, value);
  }

  void widthChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Height field with key 8.
  double _height;
  static const int heightPropertyKey = 8;

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
    onPropertyChanged(heightPropertyKey, from, value);
    heightChanged(from, value);
  }

  void heightChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// X field with key 9.
  double _x;
  static const int xPropertyKey = 9;

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
    onPropertyChanged(xPropertyKey, from, value);
    xChanged(from, value);
  }

  void xChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Y field with key 10.
  double _y;
  static const int yPropertyKey = 10;

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
    onPropertyChanged(yPropertyKey, from, value);
    yChanged(from, value);
  }

  void yChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// OriginX field with key 11.
  double _originX;
  static const int originXPropertyKey = 11;

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
    onPropertyChanged(originXPropertyKey, from, value);
    originXChanged(from, value);
  }

  void originXChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// OriginY field with key 12.
  double _originY;
  static const int originYPropertyKey = 12;

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
    onPropertyChanged(originYPropertyKey, from, value);
    originYChanged(from, value);
  }

  void originYChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (width != null) {
      onPropertyChanged(widthPropertyKey, width, width);
    }
    if (height != null) {
      onPropertyChanged(heightPropertyKey, height, height);
    }
    if (x != null) {
      onPropertyChanged(xPropertyKey, x, x);
    }
    if (y != null) {
      onPropertyChanged(yPropertyKey, y, y);
    }
    if (originX != null) {
      onPropertyChanged(originXPropertyKey, originX, originX);
    }
    if (originY != null) {
      onPropertyChanged(originYPropertyKey, originY, originY);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_width != null && exports(widthPropertyKey)) {
      context.doubleType.writeRuntimeProperty(widthPropertyKey, writer, _width);
    }
    if (_height != null && exports(heightPropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(heightPropertyKey, writer, _height);
    }
    if (_x != null && exports(xPropertyKey)) {
      context.doubleType.writeRuntimeProperty(xPropertyKey, writer, _x);
    }
    if (_y != null && exports(yPropertyKey)) {
      context.doubleType.writeRuntimeProperty(yPropertyKey, writer, _y);
    }
    if (_originX != null && exports(originXPropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(originXPropertyKey, writer, _originX);
    }
    if (_originY != null && exports(originYPropertyKey)) {
      context.doubleType
          .writeRuntimeProperty(originYPropertyKey, writer, _originY);
    }
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case widthPropertyKey:
        return width as K;
      case heightPropertyKey:
        return height as K;
      case xPropertyKey:
        return x as K;
      case yPropertyKey:
        return y as K;
      case originXPropertyKey:
        return originX as K;
      case originYPropertyKey:
        return originY as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case widthPropertyKey:
      case heightPropertyKey:
      case xPropertyKey:
      case yPropertyKey:
      case originXPropertyKey:
      case originYPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
