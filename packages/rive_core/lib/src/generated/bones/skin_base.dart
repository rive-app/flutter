/// Core automatically generated lib/src/generated/bones/skin_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:rive_core/src/generated/container_component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class SkinBase extends ContainerComponent {
  static const int typeKey = 43;
  @override
  int get coreType => SkinBase.typeKey;
  @override
  Set<int> get coreTypes =>
      {SkinBase.typeKey, ContainerComponentBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// Xx field with key 108.
  double _xx = 1;
  static const int xxPropertyKey = 108;

  /// x component of x unit vector in the bind transform
  double get xx => _xx;

  /// Change the [_xx] field value.
  /// [xxChanged] will be invoked only if the field's value has changed.
  set xx(double value) {
    if (_xx == value) {
      return;
    }
    double from = _xx;
    _xx = value;
    onPropertyChanged(xxPropertyKey, from, value);
    xxChanged(from, value);
  }

  void xxChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Yx field with key 109.
  double _yx = 0;
  static const int yxPropertyKey = 109;

  /// y component of x unit vector in the bind transform
  double get yx => _yx;

  /// Change the [_yx] field value.
  /// [yxChanged] will be invoked only if the field's value has changed.
  set yx(double value) {
    if (_yx == value) {
      return;
    }
    double from = _yx;
    _yx = value;
    onPropertyChanged(yxPropertyKey, from, value);
    yxChanged(from, value);
  }

  void yxChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Xy field with key 110.
  double _xy = 0;
  static const int xyPropertyKey = 110;

  /// x component of y unit vector in the bind transform
  double get xy => _xy;

  /// Change the [_xy] field value.
  /// [xyChanged] will be invoked only if the field's value has changed.
  set xy(double value) {
    if (_xy == value) {
      return;
    }
    double from = _xy;
    _xy = value;
    onPropertyChanged(xyPropertyKey, from, value);
    xyChanged(from, value);
  }

  void xyChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Yy field with key 111.
  double _yy = 1;
  static const int yyPropertyKey = 111;

  /// y component of y unit vector in the bind transform
  double get yy => _yy;

  /// Change the [_yy] field value.
  /// [yyChanged] will be invoked only if the field's value has changed.
  set yy(double value) {
    if (_yy == value) {
      return;
    }
    double from = _yy;
    _yy = value;
    onPropertyChanged(yyPropertyKey, from, value);
    yyChanged(from, value);
  }

  void yyChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Tx field with key 112.
  double _tx = 0;
  static const int txPropertyKey = 112;

  /// x position component of the bind transform
  double get tx => _tx;

  /// Change the [_tx] field value.
  /// [txChanged] will be invoked only if the field's value has changed.
  set tx(double value) {
    if (_tx == value) {
      return;
    }
    double from = _tx;
    _tx = value;
    onPropertyChanged(txPropertyKey, from, value);
    txChanged(from, value);
  }

  void txChanged(double from, double to);

  /// --------------------------------------------------------------------------
  /// Ty field with key 113.
  double _ty = 0;
  static const int tyPropertyKey = 113;

  /// y position component of the bind transform
  double get ty => _ty;

  /// Change the [_ty] field value.
  /// [tyChanged] will be invoked only if the field's value has changed.
  set ty(double value) {
    if (_ty == value) {
      return;
    }
    double from = _ty;
    _ty = value;
    onPropertyChanged(tyPropertyKey, from, value);
    tyChanged(from, value);
  }

  void tyChanged(double from, double to);

  @override
  void changeNonNull() {
    super.changeNonNull();
    if (xx != null) {
      onPropertyChanged(xxPropertyKey, xx, xx);
    }
    if (yx != null) {
      onPropertyChanged(yxPropertyKey, yx, yx);
    }
    if (xy != null) {
      onPropertyChanged(xyPropertyKey, xy, xy);
    }
    if (yy != null) {
      onPropertyChanged(yyPropertyKey, yy, yy);
    }
    if (tx != null) {
      onPropertyChanged(txPropertyKey, tx, tx);
    }
    if (ty != null) {
      onPropertyChanged(tyPropertyKey, ty, ty);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_xx != null && exports(xxPropertyKey)) {
      context.doubleType.writeRuntimeProperty(xxPropertyKey, writer, _xx);
    }
    if (_yx != null && exports(yxPropertyKey)) {
      context.doubleType.writeRuntimeProperty(yxPropertyKey, writer, _yx);
    }
    if (_xy != null && exports(xyPropertyKey)) {
      context.doubleType.writeRuntimeProperty(xyPropertyKey, writer, _xy);
    }
    if (_yy != null && exports(yyPropertyKey)) {
      context.doubleType.writeRuntimeProperty(yyPropertyKey, writer, _yy);
    }
    if (_tx != null && exports(txPropertyKey)) {
      context.doubleType.writeRuntimeProperty(txPropertyKey, writer, _tx);
    }
    if (_ty != null && exports(tyPropertyKey)) {
      context.doubleType.writeRuntimeProperty(tyPropertyKey, writer, _ty);
    }
  }

  @override
  bool exports(int propertyKey) {
    switch (propertyKey) {
      case xxPropertyKey:
        return _xx != 1;
      case yxPropertyKey:
        return _yx != 0;
      case xyPropertyKey:
        return _xy != 0;
      case yyPropertyKey:
        return _yy != 1;
      case txPropertyKey:
        return _tx != 0;
      case tyPropertyKey:
        return _ty != 0;
    }
    return super.exports(propertyKey);
  }

  @override
  K getProperty<K>(int propertyKey) {
    switch (propertyKey) {
      case xxPropertyKey:
        return xx as K;
      case yxPropertyKey:
        return yx as K;
      case xyPropertyKey:
        return xy as K;
      case yyPropertyKey:
        return yy as K;
      case txPropertyKey:
        return tx as K;
      case tyPropertyKey:
        return ty as K;
      default:
        return super.getProperty<K>(propertyKey);
    }
  }

  @override
  bool hasProperty(int propertyKey) {
    switch (propertyKey) {
      case xxPropertyKey:
      case yxPropertyKey:
      case xyPropertyKey:
      case yyPropertyKey:
      case txPropertyKey:
      case tyPropertyKey:
        return true;
      default:
        return super.hasProperty(propertyKey);
    }
  }
}
