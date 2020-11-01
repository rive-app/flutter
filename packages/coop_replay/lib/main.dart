// ignore_for_file: implementation_imports

import 'dart:io';
import 'dart:typed_data';
import 'package:core/coop/change.dart';
import 'package:core/coop/coop_file.dart';
import 'package:core/core.dart';
import 'package:core_generator/src/definition.dart';
import 'package:core_generator/src/property.dart';
import 'package:core_generator/src/field_types/initialize.dart';
import 'package:coop_replay/src/configuration.dart';
// ignore: implementation_imports
import 'package:core_generator/src/configuration.dart' as core_generator;
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:colorize/colorize.dart';

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

    if (config.revisionFile != null) {
      var f = File(config.revisionFile);
      if (!f.existsSync()) {
        color('Missing file ${config.revisionFile}', front: Styles.RED);
        return;
      }
      var contents = f.readAsBytesSync();
      var reader = BinaryReader.fromList(contents);
      var file = CoopFile();
      if (!file.deserialize(reader)) {
        print('FAILED TO DESERIALIZE');
        return;
      }
      color('File contains ${file.objects.length} objects.',
          front: Styles.YELLOW);
      for (final object in file.objects.values) {
        color('  Object ${keyToDef[object.key]?.name} ${object.objectId}',
            front: Styles.DEFAULT);
      }

      return;
    }

    var replayFile = ReplayFile();

    for (int i = 1; i <= config.changesetMax; i++) {
      var f = File(config.changesetsFolder + '/' + i.toString());
      if (!f.existsSync()) {
        color('Missing changeset $i', front: Styles.RED);
        continue;
      }
      var contents = f.readAsBytesSync();
      var reader = BinaryReader.fromList(contents);
      var changeset = ChangeSet();
      changeset.deserialize(reader);

      print('Changeset $i ${changeset.id} '
          '(${changeset.objects.length})');
      var accepted = replayFile.attemptChange(changeset);
      var message = accepted ? 'Accepted' : 'Rejected';
      color(
          '  $message! ${changeset.id} '
          '(${changeset.objects.length}) ${replayFile.file.objects.length}\n',
          front: accepted ? Styles.DEFAULT : Styles.RED);
      // for (final object in changeset.objects) {
      //   color(
      //       '    object ${object.objectId} has '
      //       '${object.changes.length} changes',
      //       front: Styles.YELLOW);
      //   for (final change in object.changes) {
      //     switch (change.op) {
      //       case CoreContext.addKey:
      //         color('     created', front: Styles.GREEN);
      //         break;
      //       case CoreContext.removeKey:
      //       replayFile.file.objects[change.value]
      //         color('     removed', front: Styles.RED);
      //         break;
      //     }
      //   }
      // }
    }
  });
}

class ReplayFile {
  CoopFile file = CoopFile()
    ..fileId = 1
    ..objects = {};
  int _nextChangeId = 0;
  bool attemptChange(ChangeSet changeSet) {
// Make the change on a clone.
    var modifiedFile = file.clone();
    // One thing to note is that the following will increment
    /// even if the change is rejected. That's probably ok for now.
    /// We need to evaluate at some point if we even need this
    /// serverChangeId at all (got to check what we're doing with it
    /// on the client).
    var serverChangeId = _nextChangeId++;
    modifiedFile.serverChangeId = serverChangeId;
    var serverChangeSet = ChangeSet()
      ..id = serverChangeId
      ..objects = [];
    bool validateDependencies = false;
    for (final clientObjectChanges in changeSet.objects) {
      // print("CHANGING ${objectChanges.objectId}");

      // Don't propagate changes to dependent ids. Clients build these up and
      // send them to the server for validating concurrent changes, there's no
      // need to send them to other clients.
      var serverChange = clientObjectChanges
          .clone((change) => change.op != CoreContext.dependentsKey);

      serverChangeSet.objects.add(serverChange);

      CoopFileObject object = modifiedFile.objects[serverChange.objectId];

      for (final change in clientObjectChanges.changes) {
        switch (change.op) {
          case CoreContext.addKey:
            // id is clientObjectChanges.objectId

            var reader = BinaryReader(
              ByteData.view(
                change.value.buffer,
                change.value.offsetInBytes,
                change.value.length,
              ),
            );

            var objectId = clientObjectChanges.objectId;

            // Does an object with this id already exist? Abort!
            if (modifiedFile.objects.containsKey(objectId)) {
              color(
                  '  Attempting to create an object with id '
                  '$objectId which already exists.',
                  front: Styles.RED);
              return false;
            }

            var typeKey = reader.readVarUint();
            color('  Created ${keyToDef[typeKey]?.name ?? '???'} $objectId',
                front: Styles.GREEN);
            modifiedFile.objects[objectId] = object = CoopFileObject()
              ..objectId = objectId
              ..key = typeKey;
            break;
          case CoreContext.removeKey:
            var objectId = clientObjectChanges.objectId;
            color(
                '  Delete ${keyToDef[modifiedFile.objects[objectId].key]?.name}'
                ' $objectId',
                front: Styles.RED);
            object = modifiedFile.objects.remove(objectId);
            // Destroy object with id
            break;

          default:
            // A property changed.
            print('  Property: ${keyToProperty[change.op]}');
            if (keyToProperty[change.op] != null) {
              var type = keyToProperty[change.op].type;
              var reader = BinaryReader.fromList(change.value);
              if (type.name == 'String') {
                print('    value: ${reader.readString(explicitLength: false)}');
              }
            }
            break;
        }
      }

      // now actually make changes to the object (if we have one).
      if (object != null) {
        for (final change in clientObjectChanges.changes) {
          switch (change.op) {
            case CoreContext.addKey:
              // Handled previously
              break;
            case CoreContext.removeKey:
              // Handled previously
              break;
            case CoreContext.dependentsKey:
              // need to re-validate dependencies as the dependents have
              // changed.
              validateDependencies = true;
              continue general;
            general:
            default:
              var prop = object.properties[change.op] ??= ObjectProperty();
              prop.key = change.op;
              prop.data = change.value;
              break;
          }
        }
      }
    }

    bool isChangeValid = true;
    if (validateDependencies) {
      isChangeValid = !modifiedFile.hasCyclicDependencies();
    }

    if (isChangeValid) {
      // Changes were good, modify file and propagate them to other clients.
      file = modifiedFile;
      return true;
    } else {
      // do not change the file, reject the change.
      return false;
    }
  }
}
