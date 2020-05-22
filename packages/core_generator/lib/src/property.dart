import 'package:colorize/colorize.dart';

import 'comment.dart';
import 'definition.dart';
import 'field_type.dart';
import 'key.dart';

class Property {
  final String name;
  final FieldType type;
  final Definition definition;
  String initialValue;
  bool animates = false;
  String group;
  Key key;
  String description;
  bool isNullable = false;
  bool editorOnly = false;
  bool localOnly = false;

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
    dynamic init = data['initialValue'];
    if (init is String) {
      initialValue = init;
    }
    dynamic a = data['animates'];
    if (a is bool) {
      animates = a;
    }
    dynamic g = data['group'];
    if (g is String) {
      group = g;
    }
    dynamic e = data['editorOnly'];
    if (e is bool) {
      editorOnly = e;
    }
    dynamic c = data['localOnly'];
    if (c is bool) {
      localOnly = c;
    }
    key = Key.fromJSON(data["key"]) ?? Key.forProperty(this);
  }

  String generateCode() {
    String propertyKey = '${name}PropertyKey';
    var code = StringBuffer('  /// ${'-' * 74}\n');
    code.write(comment('${capitalize(name)} field with key ${key.intValue}.',
        indent: 1));
    if (initialValue != null) {
      code.writeln('${type.dartName} _$name = $initialValue;');
    } else {
      code.writeln('${type.dartName} _$name;');
    }
    if (animates) {
      code.writeln('${type.dartName} _${name}Animated;');
      code.writeln('KeyState _${name}KeyState = KeyState.none;');
    }
    code.writeln('static const int $propertyKey = ${key.intValue};');

    if (description != null) {
      code.write(comment(description, indent: 1));
    }
    if (animates) {
      code.write(comment(
          'Get the [_$name] field value.'
          'Note this may not match the core value '
          'if animation mode is active.',
          indent: 1));
      code.writeln('${type.dartName} get $name => _${name}Animated ?? _$name;');
      code.write(
          comment('Get the non-animation [_$name] field value.', indent: 1));
      code.writeln('${type.dartName} get ${name}Core => _$name;');
    } else {
      code.writeln('${type.dartName} get $name => _$name;');
    }
    code.write(comment('Change the [_$name] field value.', indent: 1));
    code.write(comment(
        '[${name}Changed] will be invoked only if the '
        'field\'\s value has changed.',
        indent: 1));
    code.writeln('''set $name${animates ? 'Core' : ''}(${type.dartName} value) {
        if(${type.equalityCheck('_$name', 'value')}) { return; }
        ${type.dartName} from = _$name;
        _$name = value;
        onPropertyChanged($propertyKey, from, value);''');
    if (editorOnly) {
      code.writeln(
          'context?.editorPropertyChanged(this, $propertyKey, from, value);');
    }
    code.writeln('''
        ${name}Changed(from, value);
      }''');
    if (animates) {
      code.writeln('''set $name(${type.dartName} value) {
        if(context != null && context.isAnimating) {
          _${name}Animate(value, true);
          return;
        }
        ${name}Core = value;
      }''');

      code.writeln(
          '''void _${name}Animate(${type.dartName} value, bool autoKey) {
        if (_${name}Animated == value) {
          return;
        }
        ${type.dartName} from = ${name};
        _${name}Animated = value;
        ${type.dartName} to = ${name};
        onAnimatedPropertyChanged($propertyKey, autoKey, from, to);
        ${name}Changed(from, to);
      }''');

      code.writeln('${type.dartName} get ${name}Animated => _${name}Animated;');
      code.writeln('''set ${name}Animated(${type.dartName} value) =>
                        _${name}Animate(value, false);''');
      code.writeln('KeyState get ${name}KeyState => _${name}KeyState;');
      code.writeln('''set ${name}KeyState(KeyState value) {
        if (_${name}KeyState == value) {
          return;
        }
        _${name}KeyState = value;
        // Force update anything listening on this property.
        onAnimatedPropertyChanged($propertyKey, false, _${name}Animated, _${name}Animated);
      }''');
    }
    code.writeln('void ${name}Changed('
        '${type.dartName} from, ${type.dartName} to);\n');

    return code.toString();
  }

  Map<String, dynamic> serialize() {
    Map<String, dynamic> data = <String, dynamic>{'type': type.name};

    if (initialValue != null) {
      data['initialValue'] = initialValue;
    }
    if (animates) {
      data['animates'] = true;
    }
    if (group != null) {
      data['group'] = group;
    }
    data['key'] = key.serialize();
    if (description != null) {
      data['description'] = description;
    }
    if (isNullable) {
      data['nullable'] = true;
    }
    if (editorOnly) {
      data['editorOnly'] = true;
    }
    if (localOnly) {
      data['coop'] = true;
    }
    return data;
  }

  @override
  String toString() {
    return '$name(${key.intValue})';
  }
}
