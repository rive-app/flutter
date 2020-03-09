import 'dart:convert';
import 'dart:io';

import 'package:colorize/colorize.dart';
import 'package:core_generator/src/field_types/id_field_type.dart';
import 'package:dart_style/dart_style.dart';

import 'comment.dart';
import 'configuration.dart';
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

  final Configuration config;
  final List<Property> _properties = [];
  Definition _extensionOf;
  Key _key;
  bool _isAbstract = false;
  factory Definition(Configuration config, String filename) {
    var definition = definitions[filename];
    if (definition != null) {
      return definition;
    }

    var file = File(config.path + filename);
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
    definitions[filename] =
        definition = Definition.fromFilename(config, filename, definitionData);
    return definition;
  }
  Definition.fromFilename(
      this.config, this._filename, Map<String, dynamic> data) {
    dynamic extendsFilename = data['extends'];
    if (extendsFilename is String) {
      _extensionOf = Definition(config, extendsFilename);
    }
    dynamic nameValue = data['name'];
    if (nameValue is String) {
      _name = nameValue;
    }
    dynamic abstractValue = data['abstract'];
    if (abstractValue is bool) {
      _isAbstract = abstractValue;
    }
    _key = Key.fromJSON(data['key']) ?? Key.forDefinition(this);

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
  String get localFilename => _filename.indexOf(config.path) == 0
      ? _filename.substring(config.path.length)
      : _filename;

  String get name => _name;

  String get localCodeFilename => '${stripExtension(_filename)}_base.dart';
  String get concreteCodeFilename => '${stripExtension(_filename)}.dart';
  String get codeFilename => 'lib/src/generated/$localCodeFilename';

  /// Generates Dart code based on the Definition
  void generateCode(String snakeContextName) {
    String filename = codeFilename;
    Set<String> imports = {};
    final code =
        StringBuffer(comment('Core automatically generated $filename.'));
    code.writeln(comment('Do not modify manually.'));

    // Build list of classes we extend.
    List<Definition> definitionHierarchy = [];
    for (var d = this; d != null; d = d._extensionOf) {
      definitionHierarchy.add(d);
      // don't import self
      if (d != this) {
        imports.add(
            'import \'package:${config.packageName}/src/generated/${d.localCodeFilename}\';');
      }
    }
    if (_extensionOf == null || _properties.isNotEmpty) {
      // We need core if we need PropertyChanger or Core to inherit from.

      // Don't import core if it's not used
      if (_extensionOf?._name == null) {
        imports.add('import \'package:core/core.dart\';');
      }
    }
    if (_properties.isNotEmpty) {
      imports.add('import \'package:flutter/material.dart\';');
    }

    for (final property in _properties) {
      if (property.type.import == null) {
        continue;
      }
      imports.add('import \'${property.type.import}\';');
    }

    // If we extend another class, we need the import for the concrete version.
    if (_extensionOf != null) {
      imports.add(
          'import \'package:${config.packageName}/${_extensionOf.concreteCodeFilename}\';');
    }

    bool defineContextExtension = _extensionOf?._name == null;
    if (defineContextExtension) {
      imports.add('import \'$snakeContextName.dart\';');
    }

    var importList = imports.toList(growable: false)..sort();
    code.writeAll(
        importList.where((item) => item.indexOf('import \'package:') == 0),
        '\n');
    code.writeAll(
        importList.where((item) => item.indexOf('import \'package:') != 0),
        '\n');

    code.write(
        '''abstract class ${_name}Base${defineContextExtension ? '<T extends ${config.coreContextName}>' : ''} 
            extends ${_extensionOf?._name ?? 'Core<T>'} {''');
    code.write('static const int typeKey = ${_key.intValue};');
    code.write('@override int get coreType => ${_name}Base.typeKey;');

    code.write('''@override 
            Set<int> get coreTypes => 
              {${definitionHierarchy.map((d) => '${d._name}Base.typeKey').join(',')}};''');
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
      for (final property in _properties) {
        code.writeln('''if(${property.name} != null) {
          onPropertyChanged( 
          ${property.name}PropertyKey, ${property.name}, ${property.name});
        }''');
      }
      code.writeln('}');

      code.writeln('''@override
      K getProperty<K>(int propertyKey) {
      switch (propertyKey) {''');
      for (final property in _properties) {
        code.writeln('''case ${property.name}PropertyKey:
          return ${property.name} as K;''');
      }
      code.writeln('''
          default: 
          return super.getProperty<K>(propertyKey);
        }''');
      code.writeln('}');
    }
    code.writeln('}');

    var output = config.output;
    var folder =
        output != null && output.isNotEmpty && output[output.length - 1] == '/'
            ? output.substring(0, output.length - 1)
            : output;

    var file = File('$folder/$filename');
    file.createSync(recursive: true);
    var formattedCode = _formatter.format(code.toString());
    file.writeAsStringSync(formattedCode, flush: true);
  }

  void save() {
    var data = serialize();
    var serialized = const JsonEncoder.withIndent('  ').convert(data);
    var file = File(config.path + _filename);
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
  static bool generate(Configuration config) {
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
        if (config.regenerateKeys) {
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
    var snakeContextName = config.coreContextName.replaceAllMapped(
        RegExp('(.+?)([A-Z])'),
        (Match m) => "${m[1].toLowerCase()}_${m[2].toLowerCase()}");

    for (final definition in definitions.values) {
      definition.generateCode(snakeContextName);
    }

    StringBuffer ctxCode =
        StringBuffer('''import \'package:core/coop/change.dart\';
                        import \'package:core/core.dart\';
                        import 'package:binary_buffer/binary_reader.dart';
                        import 'package:binary_buffer/binary_writer.dart';
                        
                        ''');

    List<String> imports = [];
    for (final definition in definitions.values) {
      // We want the base version if there are properties or we need to instance
      // the concrete version as we need to the typeKey which is in the base
      // class.
      if (definition._properties.isNotEmpty || !definition._isAbstract) {
        imports.add('import \'${definition.localCodeFilename}\';\n');

        // We only instance concrete versions.
        if (!definition._isAbstract) {
          imports.add('import \'../../${definition.concreteCodeFilename}\';\n');
        }
      }
    }
    // Sort the imports to avoid linter warnings.
    imports.sort();
    ctxCode.writeAll(imports);

    ctxCode.writeln('''abstract class ${config.coreContextName}
                        extends CoreContext {''');
    ctxCode.writeln('''${config.coreContextName}(String fileId) 
                        : super(fileId);\n''');

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

    // Group fields by definition type.
    Map<String, List<Property>> groups = {};

    for (final definition in definitions.values) {
      for (final property in definition._properties) {
        groups[property.type.dartName] ??= <Property>[];
        groups[property.type.dartName].add(property);
      }
    }

    // Build the isPropertyId method.
    ctxCode.writeln('''@override
      bool isPropertyId(int propertyKey) {
        switch(propertyKey) {
          ''');
    for (final definition in definitions.values) {
      for (final property in definition._properties) {
        bool wroteCase = false;
        if (property.type is IdFieldType) {
          wroteCase = true;
          ctxCode.writeln(
              'case ${definition._name}Base.${property.name}PropertyKey:');
        }
        if (wroteCase) {
          ctxCode.writeln('     return true;');
        }
      }
    }
    ctxCode.writeln('''default: 
                      return false; 
          }
        }''');

    // Build the applyCoopChanges method.
    ctxCode.writeln('''@override
    void applyCoopChanges(ObjectChanges objectChanges) {
      Core<CoreContext> object = resolve(objectChanges.objectId);
      var justAdded = false;
      for (final change in objectChanges.changes) {
        var reader = BinaryReader.fromList(change.value);
        switch (change.op) {
          ''');

    ctxCode.write('''case CoreContext.addKey:
          // make sure object doesn't exist (we propagate changes to all
          // clients, so we'll receive our own adds which will result in
          // duplicates if we don't check here).
          if (object == null) {
            object = makeCoreInstance(reader.readVarInt())
              ..id = objectChanges.objectId;
            justAdded = true;
          }
          break;
        case CoreContext.removeKey:           
          // Don't remove null objects. This can happen as we acknowledge
          // changes, so we'll attempt to delete an object we ourselves have
          // already deleted.
          if (object != null) {
            remove(object);
          }
          break;''');

    groups.forEach((_, properties) {
      for (final property in properties) {
        ctxCode.write('case ${property.definition._name}Base');
        ctxCode.writeln('.${property.name}PropertyKey:');
      }

      var fieldType = properties.first.type;
      ctxCode.writeln(fieldType.decode('reader', 'value'));
      ctxCode.writeln('setObjectProperty(object, change.op, value);');
      ctxCode.writeln('break;');
    });

    ctxCode.writeln('''default:break;}}
    if(justAdded) { add(object); }}''');

    ctxCode.writeln('''@override
    Change makeCoopChange(int propertyKey, Object value) {
      var change = Change()..op = propertyKey;
       switch(propertyKey) {
          ''');

    ctxCode.write('''case CoreContext.addKey:
                    case CoreContext.removeKey:           
        if (value != null && value is int) {
          var writer = BinaryWriter(alignment: 4);
          writer.writeVarInt(value);
          change.value = writer.uint8Buffer;
        }break;''');

    groups.forEach((_, properties) {
      for (final property in properties) {
        ctxCode.write('case ${property.definition._name}Base');
        ctxCode.writeln('.${property.name}PropertyKey:');
      }

      var fieldType = properties.first.type;
      ctxCode.writeln('if(value != null && value is ${fieldType.dartName}) {');

      ctxCode.writeln('''var writer = 
            BinaryWriter(alignment: ${fieldType.encodingAlignment});''');
      ctxCode.write(fieldType.encode('writer', 'value'));
      ctxCode.writeln('change.value = writer.uint8Buffer;');
      ctxCode.writeln('}else { return null;}break;');
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
                      if(value is ${property.type.dartName}) {
                      object.${property.name} = value;
                  } else if(value == null) {object.${property.name} = null;}}''');
        } else {
          ctxCode.writeln('''if(object is ${definition._name}Base
                      && value is ${property.type.dartName}) {
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

    var output = config.output;
    var folder =
        output != null && output.isNotEmpty && output[output.length - 1] == '/'
            ? output.substring(0, output.length - 1)
            : output;

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
