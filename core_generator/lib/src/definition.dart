import 'dart:convert';
import 'dart:io';

import 'package:colorize/colorize.dart';
import 'package:dart_style/dart_style.dart';

import 'comment.dart';
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

  void generateCode() {
    var codeLocalFilename = stripExtension(_filename);
    String codeFilename = 'lib/src/generated/${codeLocalFilename}_base.dart';
    var code =
        StringBuffer(comment('Core automatically generated $codeFilename.'));
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

    code.write('''abstract class ${_name}Base 
            extends ${_extensionOf?._name ?? 'Core'} {''');
    if (!_isAbstract) {
      code.write('static const int typeKey = ${_key.intValue};');
    }
    for (final field in _properties) {
      code.write(field.generateCode());
    }
    code.write('}');
    var file = File(codeFilename);
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

  static bool generate(String coreContextName) {
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
        } else {
          properties[property.key.intValue] = property;
        }
      }
    }

    // Find max id, we use this to assign to types that don't have ids yet.
    int nextFieldId = 0;
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

    for (final definition in definitions.values) {
      definition.generateCode();
    }

    // Generate core context.
    var snakeName = coreContextName.replaceAllMapped(RegExp('(.+?)([A-Z])'),
        (Match m) => "${m[1].toLowerCase()}_${m[2].toLowerCase()}");

    StringBuffer contextCode =
        StringBuffer('import \'package:core/core.dart\';\n');
    contextCode.writeln('class $coreContextName extends CoreContext {}');

    var file = File('lib/src/generated/$snakeName.dart');
    file.createSync(recursive: true);

    var formattedCode = _formatter.format(contextCode.toString());
    file.writeAsStringSync(formattedCode, flush: true);

    // save out definitions
    for (final definition in definitions.values) {
      definition.save();
    }
    return true;
  }
}
