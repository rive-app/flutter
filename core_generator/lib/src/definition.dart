import 'dart:convert';
import 'dart:io';

import 'package:colorize/colorize.dart';
import 'package:dart_style/dart_style.dart';

import 'comment.dart';
import 'field_type.dart';
import 'key.dart';
import 'property.dart';

String stripExtension(String filename) {
  var index = filename.lastIndexOf('.');
  return index == -1 ? filename : filename.substring(0, index);
}

class Definition {
  static final Map<String, Definition> definitions = <String, Definition>{};
  static final _formatter = DartFormatter();

  final String _filename;

  String _name;

  String _basePath;
  final List<Property> _properties = [];
  Definition _extensionOf;
  Key _key;
  bool _isAbstract = false;
  factory Definition(String basePath, String filename) {
    var definition = definitions[filename];
    if (definition != null) {
      return definition;
    }

    var file = File(basePath + filename);
    var contents = file.readAsStringSync();
    Map<String, dynamic> definitionData;
    try {
      dynamic parsedJson = json.decode(contents);
      if (parsedJson is Map<String, dynamic>) {
        definitionData = parsedJson;
      }
    } on FormatException catch (error) {
      color('Invalid json data in $filename: $error', front: Styles.RED);
      return null;
    }
    definitions[filename] = definition =
        Definition.fromFilename(basePath, filename, definitionData);
    return definition;
  }
  Definition.fromFilename(
      this._basePath, this._filename, Map<String, dynamic> data) {
    dynamic extendsFilename = data['extends'];
    if (extendsFilename is String) {
      _extensionOf = Definition(_basePath, extendsFilename);
    }
    dynamic nameValue = data['name'];
    if (nameValue is String) {
      _name = nameValue;
    }
    dynamic abstractValue = data['abstract'];
    if (abstractValue is bool) {
      _isAbstract = abstractValue;
    }
    _key = _isAbstract
        ? null
        : Key.fromJSON(data['key']) ?? Key.forDefinition(this);

    dynamic properties = data['properties'];
    if (properties is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in properties.entries) {
        if (entry.value is Map<String, dynamic>) {
          _properties.add(
              Property(this, entry.key, entry.value as Map<String, dynamic>));
        }
      }
    }
  }
  String get localFilename => _filename.indexOf(_basePath) == 0
      ? _filename.substring(_basePath.length)
      : _filename;

  String get name => _name;

  String get localCodeFilename => '${stripExtension(_filename)}_base.dart';
  String get concreteCodeFilename => '${stripExtension(_filename)}.dart';
  String get codeFilename => 'lib/src/generated/$localCodeFilename';

  void generateCode(
      String outputFolder, String coreContextName, String snakeContextName) {
    String filename = codeFilename;
    var code = StringBuffer(comment('Core automatically generated $filename.'));
    code.writeln(comment('Do not modify manually.'));

    if (_extensionOf != null) {
      int foldersUp = '/'.allMatches(_filename).length;
      StringBuffer prefix = StringBuffer('../../');
      while (foldersUp != 0) {
        prefix.write('../');
        foldersUp--;
      }
      code.writeln(
          'import \'$prefix${stripExtension(_extensionOf._filename)}.dart\';');
    } else {
      code.writeln('import \'package:core/core.dart\';');
    }

    bool defineContextExtension = _extensionOf?._name == null;
    if (defineContextExtension) {
      code.writeln('import \'$snakeContextName.dart\';');
    }

    code.write(
        '''abstract class ${_name}Base${defineContextExtension ? '<T extends $coreContextName>' : ''} 
            extends ${_extensionOf?._name ?? 'Core<T>'} {''');
    if (!_isAbstract) {
      code.write('static const int typeKey = ${_key.intValue};');
      code.write('@override int get coreType => ${_name}Base.typeKey;');
    }
    for (final field in _properties) {
      code.write(field.generateCode());
    }

    if (_properties.isNotEmpty) {
// override changeNonNull to report all set fields as a change
      code.writeln('''@override
    void changeNonNull() {''');
      if (_extensionOf != null) {
        code.writeln('super.changeNonNull();');
      }
      // for (final definition in definitions.values) {
      for (final property in _properties) {
        code.writeln('''if(${property.name} != null) {
          context?.changeProperty(this, 
          ${property.name}PropertyKey, ${property.name}, ${property.name});
        }''');
      }
      // }
      code.writeln('}');
    }

    code.write('}');

    var folder = outputFolder != null &&
            outputFolder.isNotEmpty &&
            outputFolder[outputFolder.length - 1] == '/'
        ? outputFolder.substring(0, outputFolder.length - 1)
        : outputFolder;

    var file = File('$folder/$filename');
    file.createSync(recursive: true);
    var formattedCode = _formatter.format(code.toString());
    file.writeAsStringSync(formattedCode, flush: true);
  }

  void save() {
    var data = serialize();
    var serialized = const JsonEncoder.withIndent('  ').convert(data);
    var file = File(_basePath + _filename);
    file.writeAsStringSync(serialized);
  }

  Map<String, dynamic> serialize() {
    Map<String, dynamic> data = <String, dynamic>{};

    data['name'] = _name;
    if (_key != null) {
      data['key'] = _key.serialize();
    }
    if (_isAbstract) {
      data['abstract'] = true;
    }
    if (_extensionOf != null) {
      data['extends'] = _extensionOf.localFilename;
    }
    if (_properties.isNotEmpty) {
      Map<String, dynamic> propertiesData = <String, dynamic>{};
      for (final property in _properties) {
        propertiesData[property.name] = property.serialize();
      }
      data['properties'] = propertiesData;
    }

    return data;
  }

  @override
  String toString() {
    return '$_name[${_key?.intValue ?? '-'}]';
  }

  static const int minPropertyId = 3;
  static bool generate(
      String outputFolder, String coreContextName, bool regenerateKeys) {
    // Check dupe ids.
    bool runGenerator = true;
    Map<int, Definition> ids = {};
    Map<int, Property> properties = {};
    for (final definition in definitions.values) {
      if (definition._key?.intValue != null) {
        var other = ids[definition._key.intValue];
        if (other != null) {
          color('Duplicate type ids for $definition and $other.',
              front: Styles.RED);
          runGenerator = false;
        } else {
          ids[definition._key.intValue] = definition;
        }
      }
      for (final property in definition._properties) {
        if (regenerateKeys) {
          property.key = property.key.withIntValue(null);
        }
        if (property.key.isMissing) {
          continue;
        }
        var other = properties[property.key.intValue];
        if (other != null) {
          color(
              '''Duplicate field ids for ${property.definition}.$property '''
              '''and ${other.definition}.$other.''',
              front: Styles.RED);
          runGenerator = false;
        } else if (property.key.intValue < minPropertyId) {
          color(
              '${property.definition}.$property: ids less than '
              '$minPropertyId are reserved.',
              front: Styles.RED);
          runGenerator = false;
        } else {
          properties[property.key.intValue] = property;
        }
      }
    }

    // Find max id, we use this to assign to types that don't have ids yet.
    int nextFieldId = minPropertyId - 1;
    int nextId = 0;
    for (final definition in definitions.values) {
      if (definition._key != null &&
          definition._key.intValue != null &&
          definition._key.intValue > nextId) {
        nextId = definition._key.intValue;
      }
      for (final field in definition._properties) {
        if (field != null &&
            field.key.intValue != null &&
            field.key.intValue > nextFieldId) {
          nextFieldId = field.key.intValue;
        }
      }
    }

    // Increment next ids after finding max.
    nextFieldId++;
    nextId++;

    // Assign ids to types that don't have one
    for (final definition in definitions.values) {
      if (definition._key != null && definition._key.intValue == null) {
        int newId = nextId++;
        definition._key = definition._key.withIntValue(newId);
        color('${definition._name} has been assigned id ' '$newId' '',
            front: Styles.GREEN);
      }
      for (final field in definition._properties) {
        if (field != null && field.key.intValue == null) {
          int newFieldId = nextFieldId++;
          field.key = field.key.withIntValue(newFieldId);
          color(
              '${definition._name}.${field.name} has been assigned id '
              '$newFieldId'
              '',
              front: Styles.GREEN);
        }
      }
    }

    if (!runGenerator) {
      color('Not running generator due to previous errors.',
          front: Styles.YELLOW);
      return false;
    }

    // Generate core context.
    var snakeContextName = coreContextName.replaceAllMapped(
        RegExp('(.+?)([A-Z])'),
        (Match m) => "${m[1].toLowerCase()}_${m[2].toLowerCase()}");

    for (final definition in definitions.values) {
      definition.generateCode(outputFolder, coreContextName, snakeContextName);
    }

    StringBuffer ctxCode =
        StringBuffer('''import \'package:core/coop/change.dart\';
                        import \'package:core/core.dart\';
                        import 'package:binary_buffer/binary_writer.dart';
                        
                        ''');

    List<String> imports = [];
    for (final definition in definitions.values) {
      if (definition._properties.isNotEmpty) {
        imports.add('import \'${definition.localCodeFilename}\';\n');
        imports.add('import \'../../${definition.concreteCodeFilename}\';\n');
      }
    }
    // Sort the imports to avoid linter warnings.
    imports.sort();
    ctxCode.writeAll(imports);

    ctxCode.writeln('abstract class $coreContextName extends CoreContext {');
    ctxCode.writeln('$coreContextName(String fileId) : super(fileId);\n');

    ctxCode.writeln('''@override
    Core makeCoreInstance(int typeKey) {
       switch(typeKey) {
          ''');
    for (final definition in definitions.values) {
      if (definition._isAbstract) {
        continue;
      }
      ctxCode.writeln('''case ${definition._name}Base.typeKey:
        return ${definition._name}();''');
    }
    ctxCode.writeln('default:return null;}}');

    ctxCode.writeln('''@override
    Change makeCoopChange(int propertyKey, Object value) {
      var change = Change()..op = propertyKey;
       switch(propertyKey) {
          ''');

    // Group them by definition type.
    Map<FieldType, List<Property>> groups = {};

    for (final definition in definitions.values) {
      for (final property in definition._properties) {
        groups[property.type] ??= <Property>[];
        groups[property.type].add(property);
      }
    }

    ctxCode.write('''case CoreContext.addKey:
                    case CoreContext.removeKey:           
        if (value != null && value is int) {
          var writer = BinaryWriter(alignment: 4);
          writer.writeVarInt(value);
          change.value = writer.uint8Buffer;
        }break;''');

    groups.forEach((fieldType, properties) {
      for (final property in properties) {
        ctxCode.write('case ${property.definition._name}Base');
        ctxCode.writeln('.${property.name}PropertyKey:');
      }

      var fieldType = properties.first.type;
      ctxCode.writeln('if(value != null && value is ${fieldType.name}) {');

      ctxCode.writeln('''var writer = 
            BinaryWriter(alignment: ${fieldType.encodingAlignment});''');
      ctxCode.write(fieldType.encode('writer', 'value'));
      ctxCode.writeln('change.value = writer.uint8Buffer;');
      ctxCode.writeln('}break;');
    });
    ctxCode.writeln('default:break;}  return change;}');

    // Build object property setter
    ctxCode.writeln('''@override
        void setObjectProperty(Core object, int propertyKey, Object value) {
          switch(propertyKey) {
          ''');
    for (final definition in definitions.values) {
      for (final property in definition._properties) {
        ctxCode.writeln(
            'case ${definition._name}Base.${property.name}PropertyKey:');
        if (property.isNullable) {
          ctxCode.writeln('''if(object is ${definition._name}Base) {
                      if(value is ${property.type.name}) {
                      object.${property.name} = value;
                  } else if(value == null) {object.${property.name} = null;}}''');
        } else {
          ctxCode.writeln('''if(object is ${definition._name}Base
                      && value is ${property.type.name}) {
                      object.${property.name} = value;
                  }''');
        }
        ctxCode.writeln('break;');
      }
    }
    ctxCode.writeln('}}');

    // Build object property getter
    ctxCode.writeln('''@override
        Object getObjectProperty(Core object, int propertyKey) {
          switch(propertyKey) {
          ''');
    for (final definition in definitions.values) {
      for (final property in definition._properties) {
        ctxCode.writeln(
            'case ${definition._name}Base.${property.name}PropertyKey:');

        ctxCode.writeln('''if(object is ${definition._name}Base) {
                      return object.${property.name};
                  }''');
        ctxCode.writeln('break;');
      }
    }
    ctxCode.writeln('}return null;}}');

    var folder = outputFolder != null &&
            outputFolder.isNotEmpty &&
            outputFolder[outputFolder.length - 1] == '/'
        ? outputFolder.substring(0, outputFolder.length - 1)
        : outputFolder;

    var file = File('$folder/lib/src/generated/$snakeContextName.dart');
    file.createSync(recursive: true);

    var formattedCode = _formatter.format(ctxCode.toString());
    file.writeAsStringSync(formattedCode, flush: true);

    // save out definitions
    for (final definition in definitions.values) {
      definition.save();
    }
    return true;
  }
}
