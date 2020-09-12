/// Core automatically generated lib/src/generated/bones/tendon_base.dart.
/// Do not modify manually.

import 'dart:collection';
import 'package:core/core.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/src/generated/component_base.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

abstract class TendonBase extends Component {
  static const int typeKey = 44;
  @override
  int get coreType => TendonBase.typeKey;
  @override
  Set<int> get coreTypes => {TendonBase.typeKey, ComponentBase.typeKey};

  /// --------------------------------------------------------------------------
  /// Index field with key 118.
  int _index = 0;
  static const int indexPropertyKey = 118;

  /// The index used for weighting. Implicit at runtime. Required at edit time
  /// to allow undo ops to put them back in order.
  int get index => _index;

  /// Change the [_index] field value.
  /// [indexChanged] will be invoked only if the field's value has changed.
  set index(int value) {
    if (_index == value) {
      return;
    }
    int from = _index;
    _index = value;
    onPropertyChanged(indexPropertyKey, from, value);
    indexChanged(from, value);
  }

  void indexChanged(int from, int to);

  /// --------------------------------------------------------------------------
  /// BoneId field with key 95.
  Id _boneId;
  static const int boneIdPropertyKey = 95;

  /// Identifier used to track the bone this tendon connects to.
  Id get boneId => _boneId;

  /// Change the [_boneId] field value.
  /// [boneIdChanged] will be invoked only if the field's value has changed.
  set boneId(Id value) {
    if (_boneId == value) {
      return;
    }
    Id from = _boneId;
    _boneId = value;
    onPropertyChanged(boneIdPropertyKey, from, value);
    boneIdChanged(from, value);
  }

  void boneIdChanged(Id from, Id to);

  /// --------------------------------------------------------------------------
  /// Xx field with key 96.
  double _xx = 1;
  static const int xxPropertyKey = 96;

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
  /// Yx field with key 97.
  double _yx = 0;
  static const int yxPropertyKey = 97;

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
  /// Xy field with key 98.
  double _xy = 0;
  static const int xyPropertyKey = 98;

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
  /// Yy field with key 99.
  double _yy = 1;
  static const int yyPropertyKey = 99;

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
  /// Tx field with key 100.
  double _tx = 0;
  static const int txPropertyKey = 100;

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
  /// Ty field with key 101.
  double _ty = 0;
  static const int tyPropertyKey = 101;

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
    if (_index != null) {
      onPropertyChanged(indexPropertyKey, _index, _index);
    }
    if (_boneId != null) {
      onPropertyChanged(boneIdPropertyKey, _boneId, _boneId);
    }
    if (_xx != null) {
      onPropertyChanged(xxPropertyKey, _xx, _xx);
    }
    if (_yx != null) {
      onPropertyChanged(yxPropertyKey, _yx, _yx);
    }
    if (_xy != null) {
      onPropertyChanged(xyPropertyKey, _xy, _xy);
    }
    if (_yy != null) {
      onPropertyChanged(yyPropertyKey, _yy, _yy);
    }
    if (_tx != null) {
      onPropertyChanged(txPropertyKey, _tx, _tx);
    }
    if (_ty != null) {
      onPropertyChanged(tyPropertyKey, _ty, _ty);
    }
  }

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {
    super.writeRuntimeProperties(writer, idLookup);
    if (_boneId != null && exports(boneIdPropertyKey)) {
      var value = idLookup[_boneId];
      if (value != null) {
        context.uintType.writeRuntimeProperty(boneIdPropertyKey, writer, value);
      }
    }
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
      case indexPropertyKey:
        return _index != 0;
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
      case indexPropertyKey:
        return index as K;
      case boneIdPropertyKey:
        return boneId as K;
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
      case indexPropertyKey:
      case boneIdPropertyKey:
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
