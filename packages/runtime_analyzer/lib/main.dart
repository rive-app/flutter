import 'dart:io';
import 'dart:typed_data';
// ignore: implementation_imports
import 'package:core_generator/src/definition.dart';
// ignore: implementation_imports
import 'package:core_generator/src/property.dart';
// ignore: implementation_imports
import 'package:core_generator/src/field_types/initialize.dart';
import 'package:runtime_analyzer/src/configuration.dart';
// ignore: implementation_imports
import 'package:core_generator/src/configuration.dart' as core_generator;
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:colorize/colorize.dart';
import 'package:filesize/filesize.dart';

final Map<int, Definition> keyToDef = {};
final Map<int, Property> keyToProperty = {};

void main(List<String> arguments) {
  var config = Configuration.fromArguments(arguments);

  var coreGeneratorConfig = core_generator.Configuration(
      path: config.definitionsFolder,
      coreContextName: 'RiveCoreContext',
      regenerateKeys: false,
      runtimeCoreFolder: './',
      isRuntime: false,
      isVerbose: false,
      packagesFolder: './');

  // Read all definitions.
  initializeFields();

  var definitions = <Definition>[];
  Directory(config.definitionsFolder).list(recursive: true).listen((entity) {
    if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
      definitions.add(Definition(
        coreGeneratorConfig,
        entity.path.substring(config.definitionsFolder.length),
      ));
    }
  }, onDone: () {
    for (final def in definitions) {
      keyToDef[def.key.intValue] = def;
      for (final prop in def.properties) {
        keyToProperty[prop.key.intValue] = prop;
      }
    }
    for (final filename in config.filenames) {
      color('Analyzing $filename', front: Styles.YELLOW);
      var file = File(filename);
      var bytes = file.readAsBytesSync();
      var size =
          Colorize(filesize(bytes.length)).apply(Styles.LIGHT_RED).toString();
      print('  Size: $size');
      var analyzer = RuntimeAnalyzer(bytes);

      print('    --- Objects ---');
      var stats = analyzer.objectStats.values.toList();
      stats.sort((a, b) => b.size - a.size);
      for (final stat in stats) {
        String name = keyToDef[stat.objectKey]?.name ?? '???';

        var size =
            Colorize(filesize(stat.size)).apply(Styles.LIGHT_RED).toString();
        print('    ${stat.count} x $name(${stat.objectKey}) $size');
      }

      print('\n    --- Properties ---');

      for (final stat in analyzer.propertyStats.values) {
        var p = keyToProperty[stat.propertyKey];
        if (p != null) {
          stat.name = '${p.definition.name}.${p.name}';
        } else {
          stat.name = '???';
        }
      }
      var propertyStats = analyzer.propertyStats.values.toList();
      propertyStats.sort((a, b) => b.size - a.size);
      for (final stat in propertyStats) {
        var size =
            Colorize(filesize(stat.size)).apply(Styles.LIGHT_RED).toString();
        print('    ${stat.count} x ${stat.name}(${stat.propertyKey}) $size');
      }
    }
  });
}

class RuntimeProperty {
  final int propertyKey;
  final int length;
  final dynamic value;
  RuntimeProperty(this.propertyKey, this.length, this.value);
  factory RuntimeProperty.read(BinaryReader reader) {
    var key = reader.readVarUint();
    if (key == 0) {
      return null;
    }
    var property = keyToProperty[key];
    if (property == null) {
      throw UnimplementedError();
    }
    var result =
        (property.typeRuntime ?? property.type).deserializeRuntime(reader);
    return RuntimeProperty(key, result.length, result.value);
  }
}

class RuntimeObject {
  final int objectKey;
  final List<RuntimeProperty> properties;
  RuntimeObject(this.objectKey, this.properties);
  factory RuntimeObject.read(BinaryReader reader) {
    var key = reader.readVarUint();
    List<RuntimeProperty> p = [];
    while (true) {
      var property = RuntimeProperty.read(reader);
      if (property == null) {
        break;
      }
      p.add(property);
    }
    return RuntimeObject(key, p);
  }
}

class ObjectTypeStats {
  final int objectKey;
  int size = 0;
  int count = 0;
  Map<int, int> propertySizes = {};
  ObjectTypeStats(this.objectKey);
}

class PropertyStats {
  String name;
  final int propertyKey;
  int size = 0;
  int count = 0;
  PropertyStats(this.propertyKey);
}

class RuntimeAnalyzer {
  static const String rive = 'RIVE';

  Map<int, ObjectTypeStats> objectStats = {};
  Map<int, PropertyStats> propertyStats = {};

  void addStats(RuntimeObject object) {
    var objectTypeStats =
        objectStats[object.objectKey] ??= ObjectTypeStats(object.objectKey);
    objectTypeStats.count++;
    for (final property in object.properties) {
      objectTypeStats.size += property.length;
      objectTypeStats.propertySizes[property.propertyKey] ??= 0;
      objectTypeStats.propertySizes[property.propertyKey] += property.length;

      var ps = propertyStats[property.propertyKey] ??=
          PropertyStats(property.propertyKey);
      ps.count++;
      ps.size += property.length;
    }
  }

  RuntimeObject readObject(BinaryReader reader) {
    var object = RuntimeObject.read(reader);
    if (object == null) {
      return null;
    }
    addStats(object);
    return object;
  }

  RuntimeAnalyzer(Uint8List data) {
    var reader = BinaryReader.fromList(data);
    var fingerprint = rive.codeUnits;

    for (int i = 0; i < fingerprint.length; i++) {
      if (reader.readUint8() != fingerprint[i]) {
        color('Bad fingerprint.', front: Styles.RED);
        return;
      }
    }

    int readMajorVersion = reader.readVarUint();
    int readMinorVersion = reader.readVarUint();
    color('  Version $readMajorVersion.$readMinorVersion.',
        front: Styles.GREEN);
    int ownerId = reader.readVarUint();
    int fileId = reader.readVarUint();
    color('  Owner $ownerId File $fileId.', front: Styles.GREEN);

    readObject(reader);
    int numArtboards = reader.readVarUint();
    for (int i = 0; i < numArtboards; i++) {
      var numObjects = reader.readVarUint();
      for (int j = 0; j < numObjects; j++) {
        readObject(reader);
      }
      var numAnimations = reader.readVarUint();
      for (int i = 0; i < numAnimations; i++) {
        readObject(reader);

        var numKeyedObjects = reader.readVarUint();
        for (int j = 0; j < numKeyedObjects; j++) {
          readObject(reader);

          var numKeyedProperties = reader.readVarUint();
          for (int k = 0; k < numKeyedProperties; k++) {
            readObject(reader);
            var numKeyframes = reader.readVarUint();

            for (int l = 0; l < numKeyframes; l++) {
              readObject(reader);
            }
          }
        }
      }
    }
  }
}
