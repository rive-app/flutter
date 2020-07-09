import 'dart:convert';
import 'dart:io';

import 'package:colorize/colorize.dart';
import 'package:core_generator/src/field_type.dart';
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

  String get packageName => '${config.packageName}'
      '${config.isRuntime ? '/src/' + config.packageName + '_core' : ''}';

  List<Property> get properties => config.isRuntime
      ? _properties
          .where((property) => property.isRuntime)
          .toList(growable: false)
      : _properties;

  Definition _extensionOf;
  Key _key;
  bool _isAbstract = false;
  bool _exportsWithContext = false;
  bool _editorOnly = false;
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
    dynamic editorOnlyValue = data['editorOnly'];
    if (editorOnlyValue is bool) {
      _editorOnly = editorOnlyValue;
    }
    dynamic exportsWithContextValue = data['exportsWithContext'];
    if (exportsWithContextValue is bool) {
      _exportsWithContext = exportsWithContextValue;
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
    if (_extensionOf == null || properties.isNotEmpty) {
      // We need core if we need PropertyChanger or Core to inherit from.

      // Don't import core if it's not used
      if (_extensionOf?._name == null) {
        if (config.isRuntime) {
          imports.add(
              'import \'package:${config.packageName}/src/core/core.dart\';');
        } else {
          imports.add('import \'package:core/core.dart\';');
        }
      }
    }

    bool animates = false;
    for (final property in properties) {
      if (property.animates) {
        animates = true;
      }
    }
    if (animates && !config.isRuntime) {
      imports.add('import \'package:core/key_state.dart\';');
    }

    // If we extend another class, we need the import for the concrete version.
    if (_extensionOf != null) {
      imports.add(
          'import \'package:$packageName/${_extensionOf.concreteCodeFilename}\';');
    }

    bool defineContextExtension = _extensionOf?._name == null;
    if (defineContextExtension && !config.isRuntime) {
      imports.add(
          'import \'package:${config.packageName}/src/generated/$snakeContextName.dart\';');
    }

    if (properties.isNotEmpty) {
      if (!config.isRuntime) {
        // Do we need these at runtime? Definitely not the binary writer...
        imports.add(
            'import \'package:${config.isRuntime ? '${config.packageName}/src/utilities' : 'utilities'}'
            '/binary_buffer/binary_writer.dart\';');
        imports.add('import \'dart:collection\';');
      }
      if (config.isRuntime) {
        imports.add(
            'import \'package:${config.packageName}/src/core/core.dart\';');
      } else {
        imports.add('import \'package:core/core.dart\';');
      }
    }

    var exportsWithContext = _exportsWithContext && !config.isRuntime;
    if (exportsWithContext) {
      imports.add('import \'package:core/export_rules.dart\';');
    }

    var importList = imports.toList(growable: false)..sort();

    code.writeAll(
        importList.where((item) => item.indexOf('import \'package:') != 0),
        '\n');
    code.writeAll(
        importList.where((item) => item.indexOf('import \'package:') == 0),
        '\n');

    code.write(
        '''abstract class ${_name}Base${defineContextExtension ? '<T extends ${config.isRuntime ? 'CoreContext' : config.coreContextName}>' : ''} 
            extends ${_extensionOf?._name ?? 'Core<T>'} ''');
    if (exportsWithContext) {
      code.write(' implements ExportRules ');
    }
    code.writeln('{');
    if (exportsWithContext) {
      code.writeln('''@override
      bool get exportAsContextObject => true;
      ''');
    }

    code.write('static const int typeKey = ${_key.intValue};');
    code.write('@override int get coreType => ${_name}Base.typeKey;');

    code.write('''@override 
            Set<int> get coreTypes => 
              {${definitionHierarchy.map((d) => '${d._name}Base.typeKey').join(',')}};''');
    for (final field in properties) {
      code.write(field.generateCode(config.isRuntime));
    }

    if (properties.isNotEmpty && !config.isRuntime) {
      // override changeNonNull to report all set fields as a change
      code.writeln('''@override
    void changeNonNull() {''');
      if (_extensionOf != null) {
        code.writeln('super.changeNonNull();');
      }
      for (final property in properties) {
        code.writeln('''if(${property.name} != null) {
          onPropertyChanged( 
          ${property.name}PropertyKey, ${property.name}, ${property.name});
        }''');
      }
      code.writeln('}');

      // Write serializer.
      StringBuffer runtimeRemapDefinition = StringBuffer();
      code.writeln('''@override
    void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {''');
      if (_extensionOf != null) {
        code.writeln('super.writeRuntimeProperties(writer, idLookup);');
      }
      for (final property in properties) {
        if (!property.isRuntime) {
          continue;
        }
        if (property.type is IdFieldType) {
          code.writeln('''if(_${property.name} != null) {
          var value = idLookup[_${property.name}];
          if(value != null) {
            context.intType.writeProperty(${property.name}PropertyKey, writer, value);
          }
        }''');
        } else if (property.type != property.typeRuntime &&
            property.typeRuntime != null) {
          runtimeRemapDefinition.writeln(
              '${property.typeRuntime.dartName} runtimeValue${property.capitalizedName}(${property.type.dartName} editorValue);');
          code.writeln('''if(_${property.name} != null) {
          var runtimeValue = runtimeValue${property.capitalizedName}(_${property.name});
          context.${property.typeRuntime.uncapitalizedName}Type.writeProperty(${property.name}PropertyKey, writer, runtimeValue);
        }''');
        } else {
          code.writeln('''if(_${property.name} != null) {
          context.${property.type.uncapitalizedName}Type.writeProperty(${property.name}PropertyKey, writer, _${property.name});
        }''');
        }
      }
      code.writeln('}');

      if (runtimeRemapDefinition.isNotEmpty) {
        code.write(runtimeRemapDefinition.toString());
      }

      code.writeln('''@override
      K getProperty<K>(int propertyKey) {
      switch (propertyKey) {''');
      for (final property in properties) {
        code.writeln('''case ${property.name}PropertyKey:
          return ${property.name} as K;''');
      }
      code.writeln('''
          default: 
          return super.getProperty<K>(propertyKey);
        }''');
      code.writeln('}');

      code.writeln('''@override
      bool hasProperty(int propertyKey) {
      switch (propertyKey) {''');
      for (final property in properties) {
        code.writeln('case ${property.name}PropertyKey:');
      }
      code.writeln('return true;');
      code.writeln('''
          default: 
          return super.hasProperty(propertyKey);
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
    if (_editorOnly) {
      data['editorOnly'] = true;
    }
    if (_exportsWithContext) {
      data['exportsWithContext'] = true;
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

    definitions.removeWhere((key, definition) => definition._editorOnly);

    // Generate core context.
    var snakeContextName = config.coreContextName.replaceAllMapped(
        RegExp('(.+?)([A-Z])'),
        (Match m) => "${m[1].toLowerCase()}_${m[2].toLowerCase()}");

    for (final definition in definitions.values) {
      definition.generateCode(snakeContextName);
    }

    StringBuffer ctxCode = StringBuffer('');

    List<String> imports = [
      if (!config.isRuntime) 'import \'package:core/coop/change.dart\';',
      config.isRuntime
          ? 'import \'package:${config.packageName}/src/core/core.dart\';'
          : 'import \'package:core/core.dart\';',
      if (!config.isRuntime)
        'import \'package:utilities/binary_buffer/binary_reader.dart\';',
      config.isRuntime
          ? 'import \'package:${config.packageName}/src/core/field_types/core_field_type.dart\';'
          : 'import \'package:core/field_types/core_field_type.dart\';',
      if (!config.isRuntime)
        'import \'package:utilities/binary_buffer/binary_writer.dart\';',
      if (!config.isRuntime) 'import \'package:core/key_state.dart\';'
    ];
    for (final definition in definitions.values) {
      // We want the base version if there are properties or we need to instance
      // the concrete version as we need to the typeKey which is in the base
      // class.
      if (definition.properties.isNotEmpty || !definition._isAbstract) {
        imports.add('import \'package:${config.packageName}/'
            'src/generated/${definition.localCodeFilename}\';\n');

        // We only instance concrete versions.
        if (!definition._isAbstract) {
          imports.add('import \'package:${definition.packageName}'
              '/${definition.concreteCodeFilename}\';\n');
        }
      }
    }

    // Group fields by definition type.
    Map<FieldType, List<Property>> groups = {};
    Map<String, List<Property>> propertyGroupToKey = {};

    for (final definition in definitions.values) {
      for (final property in definition.properties) {
        var exportType = property.getExportType(config.isRuntime);
        groups[exportType] ??= <Property>[];
        groups[exportType].add(property);
        if (property.group != null) {
          var list = propertyGroupToKey[property.group] ??= [];
          list.add(property);
        }
      }
    }

    if (config.isRuntime) {
      // add imports for core field types
      for (final type in groups.keys) {
        imports
            .add('import \'package:${config.packageName}/src/core/field_types/'
                'core_${type.snakeName}_type.dart\';');
      }
    }

    // Split imports and package imports.  Sort the imports to avoid linter
    // warnings.
    ctxCode.writeAll(imports
        .where((import) => import.startsWith('import \'package:'))
        .toList()
          ..sort());
    ctxCode.writeln('\n');
    ctxCode.writeAll(imports
        .where((import) => !import.startsWith('import \'package:'))
        .toList()
          ..sort());

    if (config.isRuntime) {
      ctxCode.writeln('// ignore: avoid_classes_with_only_static_members');
      ctxCode.writeln('class ${config.coreContextName} {');
    } else {
      ctxCode.writeln('''abstract class ${config.coreContextName}
                        extends CoreContext {''');
    }

    if (config.isRuntime) {
      ctxCode.writeln('''static Core makeCoreInstance(int typeKey) {
       switch(typeKey) {
          ''');
    } else {
      ctxCode.writeln('''@override
    Core makeCoreInstance(int typeKey) {
       switch(typeKey) {
          ''');
    }
    for (final definition in definitions.values) {
      if (definition._isAbstract) {
        continue;
      }
      ctxCode.writeln('''case ${definition._name}Base.typeKey:
        return ${definition._name}();''');
    }
    ctxCode.writeln('default:return null;}}');

    if (!config.isRuntime) {
      // Get property key group id.
      ctxCode.write(comment(
          'Get an integer representing the group for this property. Use this to quickly hash groups of properties together and use the string version to key labels/names from.',
          indent: 1));
      ctxCode.writeln('''static int propertyKeyGroupHashCode(int propertyKey) {
      switch (propertyKey) {''');

      List<String> propertyGroupToKeyKeys =
          propertyGroupToKey.keys.toList(growable: false);
      propertyGroupToKey.forEach((name, list) {
        for (final property in list) {
          ctxCode.write('case ${property.definition._name}Base');
          ctxCode.writeln('.${property.name}PropertyKey:');
        }
        ctxCode.writeln('return ${propertyGroupToKeyKeys.indexOf(name) + 1};');
      });
      ctxCode.writeln('default: return 0; }}');

      ctxCode.writeln('''static String objectName(int typeKey) {
      switch (typeKey) {''');
      for (final definition in definitions.values) {
        if (definition._isAbstract) {
          continue;
        }
        ctxCode.writeln('case ${definition._name}Base.typeKey:');
        ctxCode.writeln('return \'${definition._name}\';');
      }
      ctxCode.writeln('}return null;}');

      ctxCode.writeln('''static String propertyKeyGroupName(int propertyKey) {
      switch (propertyKey) {''');
      propertyGroupToKey.forEach((name, list) {
        for (final property in list) {
          ctxCode.write('case ${property.definition._name}Base');
          ctxCode.writeln('.${property.name}PropertyKey:');
        }
        ctxCode.writeln('return \'$name\';');
      });
      ctxCode.writeln('default: return null; }}');

      ctxCode.writeln('''static String propertyKeyName(int propertyKey) {
      switch (propertyKey) {''');
      for (final definition in definitions.values) {
        for (final property in definition.properties) {
          ctxCode.write('case ${property.definition._name}Base');
          ctxCode.writeln('.${property.name}PropertyKey:');
          ctxCode.writeln('return \'${property.name}\';');
        }
      }
      ctxCode.writeln('default: return null; }}');

      // Iterate used fields to get getters.
      for (final fieldType in groups.keys) {
        ctxCode.writeln(
            '${fieldType.runtimeCoreType} get ${fieldType.uncapitalizedName}Type;');
      }
      ctxCode.writeln('');

      // Build the applyCoopChanges method.
      ctxCode.writeln('''@override
    void applyCoopChanges(ObjectChanges objectChanges) {
      Core<CoreContext> object = resolve(objectChanges.objectId);
      var justAdded = false;
      if (object == null) {
        // Only look for the addKey if the object was null, becase we propagate
        // changes to all clients, we'll receive our own adds which will result 
        // in duplicates if we don't do this only for null objects.
        Change addChange = objectChanges.changes.firstWhere(
            (change) => change.op == CoreContext.addKey,
            orElse: () => null);
        if(addChange == null) {
          // Null object and no creation change.
          return;
        }
        var reader = BinaryReader.fromList(addChange.value);
        object = makeCoreInstance(reader.readVarInt());
        if (object != null) {
          object.id = objectChanges.objectId;
          justAdded = true;
        } else {
          // object couldn't be created, don't attempt to change any properties on
          // a null object, so return.
          return;
        }
      }
      for (final change in objectChanges.changes) {
        var reader = BinaryReader.fromList(change.value);
        switch (change.op) {
          ''');

      ctxCode.write('''case CoreContext.addKey:
          // Ignore, we looked for it earlier if we needed to make the object.
          break;
        case CoreContext.removeKey:           
          // Don't remove null objects. This can happen as we acknowledge
          // changes, so we'll attempt to delete an object we ourselves have
          // already deleted.
          if (object != null) {
            removeObject(object);
          }
          break;''');

      groups.forEach((_, properties) {
        for (final property in properties) {
          ctxCode.write('case ${property.definition._name}Base');
          ctxCode.writeln('.${property.name}PropertyKey:');
        }

        var fieldType = properties.first.type;

        ctxCode.writeln(
            'var value = ${fieldType.uncapitalizedName}Type.deserialize(reader);');
        ctxCode.writeln(
            'set${fieldType.capitalizedName}(object, change.op, value);');
        ctxCode.writeln('break;');
      });

      ctxCode.writeln('''default:break;}}
    if(justAdded) { addObject(object); }}''');

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
        ctxCode
            .writeln('if(value != null && value is ${fieldType.dartName}) {');

        // ctxCode.writeln('''var writer =
        //       BinaryWriter(alignment: ${fieldType.encodingAlignment});''');
        // ctxCode.write(fieldType.encode('writer', 'value'));
        ctxCode.writeln(
            'change.value = ${fieldType.uncapitalizedName}Type.serialize(value);');
        ctxCode.writeln('}else { return null;}break;');
      });
      ctxCode.writeln('default:break;}  return change;}');
    }

    // Build object property setter
    ctxCode.writeln('''${config.isRuntime ? 'static' : '@override'}
        void setObjectProperty(Core object, int propertyKey, Object value) {
          switch(propertyKey) {
          ''');
    for (final definition in definitions.values) {
      for (final property in definition.properties) {
        ctxCode.writeln(
            'case ${definition._name}Base.${property.name}PropertyKey:');
        if (property.isNullable) {
          ctxCode.writeln('''if(object is ${definition._name}Base) {
                      if(value is ${property.getExportType(config.isRuntime).dartName}) {
                      object.${property.name} = value;
                  } else if(value == null) {object.${property.name} = null;}}''');
        } else {
          ctxCode.writeln('''if(object is ${definition._name}Base
                      && value is ${property.getExportType(config.isRuntime).dartName}) {
                      object.${property.name} = value;
                  }''');
        }
        ctxCode.writeln('break;');
      }
    }
    ctxCode.writeln('}}');
    // We want a way to specifically set only core (non-animated) properties.
    if (!config.isRuntime) {
      ctxCode.writeln('''${config.isRuntime ? 'static' : '@override'}
        void setObjectPropertyCore(Core object, int propertyKey, Object value) {
          switch(propertyKey) {
          ''');
      for (final definition in definitions.values) {
        for (final property in definition.properties) {
          var setterName =
              property.animates ? '${property.name}Core' : property.name;
          ctxCode.writeln(
              'case ${definition._name}Base.${property.name}PropertyKey:');
          if (property.isNullable) {
            ctxCode.writeln('''if(object is ${definition._name}Base) {
                      if(value is ${property.getExportType(config.isRuntime).dartName}) {
                      object.$setterName = value;
                  } else if(value == null) {object.$setterName = null;}}''');
          } else {
            ctxCode.writeln('''if(object is ${definition._name}Base
                      && value is ${property.getExportType(config.isRuntime).dartName}) {
                      object.$setterName = value;
                  }''');
          }
          ctxCode.writeln('break;');
        }
      }
      ctxCode.writeln('}}');
    }

    if (!config.isRuntime) {
      ctxCode.writeln('static bool animates(int propertyKey) {'
          'switch(propertyKey) {');
      bool hasAnimated = false;
      for (final definition in definitions.values) {
        for (final property in definition.properties) {
          if (property.animates) {
            ctxCode.writeln('case ${definition._name}Base'
                '.${property.name}PropertyKey:');
            hasAnimated = true;
            continue;
          }
        }
      }
      if (hasAnimated) {
        ctxCode.writeln('return true;');
      }
      ctxCode.writeln('default: return false;');
      ctxCode.writeln('}}');

      ctxCode.writeln('''
        static KeyState getKeyState(Core object, int propertyKey) {
          switch(propertyKey) {
          ''');
      for (final definition in definitions.values) {
        for (final property in definition.properties) {
          if (!property.animates) {
            continue;
          }
          ctxCode.writeln(
              'case ${definition._name}Base.${property.name}PropertyKey:');
          ctxCode.writeln('return (object as ${property.definition._name}Base).'
              '${property.name}KeyState;');

          ctxCode.writeln('break;');
        }
      }
      ctxCode.writeln('default: return null;');
      ctxCode.writeln('}}');

      ctxCode.writeln('''
        static void setKeyState(Core object, int propertyKey, KeyState value) {
          switch(propertyKey) {
          ''');
      for (final definition in definitions.values) {
        for (final property in definition.properties) {
          if (!property.animates) {
            continue;
          }
          ctxCode.writeln(
              'case ${definition._name}Base.${property.name}PropertyKey:');

          ctxCode.writeln('''if(object is ${definition._name}Base) {
                      object.${property.name}KeyState = value;
                  }''');

          ctxCode.writeln('break;');
        }
      }
      ctxCode.writeln('}}');

      ctxCode.writeln('''@override
        void resetAnimated(Core object, int propertyKey) {
          switch(propertyKey) {
          ''');
      for (final definition in definitions.values) {
        for (final property in definition.properties) {
          if (!property.animates) {
            continue;
          }
          ctxCode.writeln(
              'case ${definition._name}Base.${property.name}PropertyKey:');

          ctxCode.writeln('''if(object is ${definition._name}Base) {
                      object.${property.name}Animated = null;
                      object.${property.name}KeyState = KeyState.none;
                  }''');

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
        for (final property in definition.properties) {
          ctxCode.writeln(
              'case ${definition._name}Base.${property.name}PropertyKey:');

          ctxCode.writeln('''if(object is ${definition._name}Base) {
                      return object.${property.name};
                  }''');
          ctxCode.writeln('break;');
        }
      }
      ctxCode.writeln('}return null;}');

      // Build a way to determine if a property syncs to coop
      ctxCode.writeln('''
        @override
        bool isCoopProperty(int propertyKey) {
          switch(propertyKey) {
          ''');
      bool wroteCoopCase = false;

      for (final definition in definitions.values) {
        for (final property in definition.properties) {
          if (!property.isCoop) {
            wroteCoopCase = true;
            ctxCode.write('case ${property.definition._name}Base');
            ctxCode.write('.${property.name}PropertyKey:');
          }
        }
      }
      if (wroteCoopCase) {
        ctxCode.write('return false;');
      }
      ctxCode.write('default: return true; } }');

      // Build a way to determine if a property exports to runtime
      ctxCode.writeln('''
        @override
        bool isRuntimeProperty(int propertyKey) {
          switch(propertyKey) {
          ''');
      bool wroteRuntimeCase = false;
      for (final definition in definitions.values) {
        for (final property in definition.properties) {
          if (!property.isRuntime) {
            wroteRuntimeCase = true;
            ctxCode.write('case ${property.definition._name}Base');
            ctxCode.write('.${property.name}PropertyKey:');
          }
        }
      }
      if (wroteRuntimeCase) {
        ctxCode.write('return false;');
      }
      ctxCode.write('default: return true; } }');
    }

    if (config.isRuntime) {
      // Define static versions of each core field type. We can do this at
      // runtime because we don't neeed key generators. We also assume names
      // match.
      for (final type in groups.keys) {
        //static CoreFieldType intType = CoreIntType();

        var capitalizedType =
            '${type.dartName[0].toUpperCase()}${type.dartName.substring(1)}'
                .replaceAll('<', '')
                .replaceAll('>', '');
        ctxCode.writeln('static CoreFieldType ${type.uncapitalizedName}Type = '
            'Core${capitalizedType}Type();');
      }
    }
    ctxCode.writeln('''
      ${config.isRuntime ? 'static' : '@override'}
      CoreFieldType coreType(int propertyKey) {
        switch(propertyKey) {
        ''');
    groups.forEach((type, properties) {
      for (final property in properties) {
        ctxCode.write('case ${property.definition._name}Base');
        ctxCode.write('.${property.name}PropertyKey:');
      }
      ctxCode.writeln('return ${type.uncapitalizedName}Type;');
    });
    ctxCode.writeln('default:return null;');
    ctxCode.writeln('}}');

    // Build is/setter/getter for specific types.

    groups.forEach((type, properties) {
      var capitalizedType = type.capitalizedName;
      ctxCode.writeln('''
        static ${type.dartName} get$capitalizedType(Core object, int propertyKey) {
          switch(propertyKey) {
          ''');
      for (final property in properties) {
        ctxCode.write('case ${property.definition._name}Base');
        ctxCode.write('.${property.name}PropertyKey:');
        ctxCode.writeln(
            'return (object as ${property.definition._name}Base).${property.name};');
      }

      ctxCode.writeln('}return ${type.defaultValue};}');
    });

    groups.forEach((type, properties) {
      var capitalizedType = type.capitalizedName;
      ctxCode.writeln('''
        static void set$capitalizedType(Core object, int propertyKey, ${type.dartName} value) {
          switch(propertyKey) {
          ''');
      bool animates = false;
      for (final property in properties) {
        if (property.animates) {
          animates = true;
        }
        ctxCode.write('case ${property.definition._name}Base');
        ctxCode.write('.${property.name}PropertyKey:');
        if (!config.isRuntime && property.animates) {
          // In the editor we want to make sure that when we're changing a core
          // property, it's not the animated value that we're setting.
          ctxCode.writeln('(object as ${property.definition._name}Base).'
              '${property.name}Core = value;break;');
        } else {
          ctxCode.writeln(
              '(object as ${property.definition._name}Base).${property.name}'
              ' = value;break;');
        }
      }

      ctxCode.writeln('}}');
      if (!config.isRuntime && animates) {
        ctxCode.writeln('''
        static void animate$capitalizedType(Core object, int propertyKey, 
          ${type.dartName} value) {
          switch(propertyKey) {
          ''');
        for (final property in properties) {
          if (!property.animates) {
            continue;
          }
          ctxCode.write('case ${property.definition._name}Base');
          ctxCode.write('.${property.name}PropertyKey:');
          ctxCode.writeln('(object as ${property.definition._name}Base).'
              '${property.name}Animated = value;break;');
        }

        ctxCode.writeln('}}');
      }
    });
    ctxCode.writeln('}');

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
