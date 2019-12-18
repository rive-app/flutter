// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'component.dart';

// **************************************************************************
// CoreTypeGenerator
// **************************************************************************

class Component extends ComponentBase {
  String get name => _name;

  set name(String value) {
    if (_name == value) {
      return;
    }
    context?.changeProperty(this, nameCoreKey, _name, value, null);
    String from = _name;
    _name = value;
    _nameChanged(from, value);
  }

  void serialize(Serializer serializer) {
    print('serializing ComponentBase');
    serializer.writeValue('name', _name);
  }
}
