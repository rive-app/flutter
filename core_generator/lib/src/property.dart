import 'package:colorize/colorize.dart';

import 'comment.dart';
import 'definition.dart';
import 'field_type.dart';
import 'key.dart';

class Property {
  final String name;
  final FieldType type;
  final Definition definition;
  Key key;
  String description;
  bool isNullable = false;

  factory Property(Definition type, String name, Map<String, dynamic> data) {
    var fieldType = FieldType.find(data["type"]);
    if (fieldType == null) {
      color('Invalid field type ${data['type']}.', front: Styles.RED);
      return null;
    }
    return Property.make(type, name, fieldType, data);
  }

  Property.make(
      this.definition, this.name, this.type, Map<String, dynamic> data) {
    dynamic descriptionValue = data["description"];
    if (descriptionValue is String) {
      description = descriptionValue;
    }
    dynamic nullableValue = data['nullable'];
    if (nullableValue is bool) {
      isNullable = nullableValue;
    }
    key = Key.fromJSON(data["key"]) ?? Key.forProperty(this);
  }

  String generateCode() {
    String propertyKey = '${name}PropertyKey';
    var code = StringBuffer('  /// ${'-' * 74}\n');
    code.write(comment('${capitalize(name)} field with key ${key.intValue}.',
        indent: 1));
    code.writeln('${type.name} _$name;');
    code.writeln('static const int $propertyKey = ${key.intValue};');

    if (description != null) {
      code.write(comment(description, indent: 1));
    }
    code.writeln('${type.name} get $name => _$name;');
    code.write(comment('Change the [_$name] field value.', indent: 1));
    code.write(comment(
        '[${name}Changed] will be invoked only if the '
        'field\'\s value has changed.',
        indent: 1));

    code.writeln('''set $name(${type.name} value) {
        if(${type.equalityCheck('_$name', 'value')}) { return; }
        ${type.name} from = _$name;
        _$name = value;
        ${name}Changed(from, value);
      }''');
    code.writeln('''@mustCallSuper
    void ${name}Changed(${type.name} from, ${type.name} to) {
        onPropertyChanged($propertyKey, from, to);
      }\n''');

    return code.toString();
  }

  Map<String, dynamic> serialize() {
    Map<String, dynamic> data = <String, dynamic>{'type': type.name};

    data['key'] = key.serialize();
    if (description != null) {
      data['description'] = description;
    }
    if (isNullable) {
      data['nullable'] = true;
    }
    return data;
  }

  @override
  String toString() {
    return '$name(${key.intValue})';
  }
}
