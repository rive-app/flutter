// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'color_component.dart';

// **************************************************************************
// CoreTypeGenerator
// **************************************************************************

class ColorComponent extends ColorComponentBase {
  @override
  int get colorValue => _colorValue;
  @override
  set colorValue(int value) {
    if (_colorValue == value) {
      return;
    }
    context?.changeProperty(this, colorValueCoreKey, _colorValue, value, null);
    _colorValue = value;
  }

  Float32List get myArray => _myArray;

  set myArray(Float32List value) {
    if (_myArray == value) {
      return;
    }
    context?.changeProperty(this, myArrayCoreKey, _myArray, value, null);
    _myArray = value;
  }

  @override
  void serialize(Serializer serializer) {
    super.serialize(serializer);
    print('serializing ColorComponentBase');
    serializer.writeValue('colorValue', _colorValue);
    serializer.writeValue('myArray', _myArray);
  }
}
