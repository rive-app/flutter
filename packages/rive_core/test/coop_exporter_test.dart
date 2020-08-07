import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/coop_importer.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';

bool _isSorted<T>(List<T> list, [int Function(T, T) compare]) {
  if (list.length < 2) return true;
  compare ??= (T a, T b) => (a as Comparable<T>).compareTo(b);
  T prev = list.first;
  for (var i = 1; i < list.length; i++) {
    T next = list[i];
    if (compare(prev, next) > 0) return false;
    prev = next;
  }
  return true;
}

void main() {
  test('Export a Rive Coop file', () {
    var file =
        File('./${Directory.current.path.endsWith('/test') ? '' : 'test/'}'
            'assets/file_teeny_tiny.coop');
    var data = file.readAsBytesSync();
    var riveFile = RiveFile('0', localDataPlatform: null);
    var coopImporter = CoopImporter(core: riveFile);
    coopImporter.import(data);
    expect(riveFile.artboards.length, 1);
    expect(riveFile.artboards.first.drawables.isNotEmpty, true);

    var exporter = RuntimeExporter(
        core: riveFile, info: RuntimeHeader(ownerId: 1, fileId: 1));

    expect(riveFile.artboards.first.drawables.isNotEmpty, true);

    var exportedRiveBinary = exporter.export();

    var firstArtboard = riveFile.artboards.first;
    // Make sure drawables got sorted during export...
    expect(
        _isSorted(firstArtboard.drawables,
            (Drawable a, Drawable b) => a.drawOrder.compareTo(b.drawOrder)),
        true);

    var fileOut =
        File('./${Directory.current.path.endsWith('/test') ? '' : 'test/'}'
            'assets/file_teeny_tiny.riv');
    fileOut.writeAsBytesSync(exportedRiveBinary);
  });
}
