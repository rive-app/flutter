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
  bool isRuntime = true;
  bool isCoop = true;
  FieldType typeRuntime;

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
    if (e is bool && e) {
      isCoop = false;
    }
    dynamic r = data['runtime'];
    if (r is bool) {
      isRuntime = r;
    }
    dynamic c = data['coop'];
    if (c is bool) {
      isCoop = c;
    }
    dynamic rt = data['typeRuntime'];
    if (rt is String) {
      typeRuntime = FieldType.find(rt);
    }
    key = Key.fromJSON(data["key"]) ?? Key.forProperty(this);
  }

  FieldType getExportType(bool forRuntime) =>
      forRuntime ? typeRuntime ?? type : type;

  String generateCode(bool forRuntime) {
    bool exportAnimates = animates && !forRuntime;
    var exportType = getExportType(forRuntime);
    String propertyKey = '${name}PropertyKey';
    var code = StringBuffer('  /// ${'-' * 74}\n');
    code.write(comment('${capitalize(name)} field with key ${key.intValue}.',
        indent: 1));
    if (initialValue != null) {
      code.writeln('${exportType.dartName} _$name = $initialValue;');
    } else {
      code.writeln('${exportType.dartName} _$name;');
    }
    if (exportAnimates) {
      code.writeln('${exportType.dartName} _${name}Animated;');
      code.writeln('KeyState _${name}KeyState = KeyState.none;');
    }
    code.writeln('static const int $propertyKey = ${key.intValue};');

    if (description != null) {
      code.write(comment(description, indent: 1));
    }
    if (exportAnimates) {
      code.write(comment(
          'Get the [_$name] field value.'
          'Note this may not match the core value '
          'if animation mode is active.',
          indent: 1));
      code.writeln(
          '${exportType.dartName} get $name => _${name}Animated ?? _$name;');
      code.write(
          comment('Get the non-animation [_$name] field value.', indent: 1));
      code.writeln('${exportType.dartName} get ${name}Core => _$name;');
    } else {
      code.writeln('${exportType.dartName} get $name => _$name;');
    }
    code.write(comment('Change the [_$name] field value.', indent: 1));
    code.write(comment(
        '[${name}Changed] will be invoked only if the '
        'field\'\s value has changed.',
        indent: 1));
    code.writeln(
        '''set $name${exportAnimates ? 'Core' : ''}(${exportType.dartName} value) {
        if(${exportType.equalityCheck('_$name', 'value')}) { return; }
        ${exportType.dartName} from = _$name;
        _$name = value;''');
    // Property change callbacks to the context don't propagate at runtime.
    if (!forRuntime) {
      code.writeln('onPropertyChanged($propertyKey, from, value);');
      if (!isCoop) {
        code.writeln(
            'context?.editorPropertyChanged(this, $propertyKey, from, value);');
      }
    }
    // Change callbacks do as we use those to trigger dirty states.
    code.writeln('''
        ${name}Changed(from, value);
      }''');
    if (exportAnimates) {
      code.writeln('''set $name(${exportType.dartName} value) {
        if(context != null && context.isAnimating) {
          _${name}Animate(value, true);
          return;
        }
        ${name}Core = value;
      }''');

      code.writeln(
          '''void _${name}Animate(${exportType.dartName} value, bool autoKey) {
        if (_${name}Animated == value) {
          return;
        }
        ${exportType.dartName} from = ${name};
        _${name}Animated = value;
        ${exportType.dartName} to = ${name};
        onAnimatedPropertyChanged($propertyKey, autoKey, from, to);
        ${name}Changed(from, to);
      }''');

      code.writeln(
          '${exportType.dartName} get ${name}Animated => _${name}Animated;');
      code.writeln('''set ${name}Animated(${exportType.dartName} value) =>
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
        '${exportType.dartName} from, ${exportType.dartName} to);\n');

    return code.toString();
  }

  Map<String, dynamic> serialize() {
    Map<String, dynamic> data = <String, dynamic>{'type': type.name};
    if (typeRuntime != null) {
      data['typeRuntime'] = typeRuntime.name;
    }

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
    if (!isRuntime) {
      data['runtime'] = false;
    }
    if (!isCoop) {
      data['coop'] = false;
    }
    return data;
  }

  @override
  String toString() {
    return '$name(${key.intValue})';
  }

  String get capitalizedName => '${name[0].toUpperCase()}${name.substring(1)}'
      .replaceAll('<', '')
      .replaceAll('>', '');
}
