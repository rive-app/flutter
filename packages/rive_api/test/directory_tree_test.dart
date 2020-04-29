/// Directory tree tests
import 'dart:convert';
import 'package:test/test.dart';
import 'package:rive_api/src/model/directory_tree.dart';

final dirTreeJsonSingle = json.encode([
  {'id': 1, 'name': 'Top Dir 1', 'parent': null, 'order': 0},
]);

final dirTreeJsonFlat = json.encode([
  {'id': 1, 'name': 'Top Dir 1', 'parent': null, 'order': 0},
  {'id': 2, 'name': 'Top Dir 2', 'parent': null, 'order': 1},
  {'id': 3, 'name': 'Top Dir 3', 'parent': null, 'order': 2},
]);

final dirTreeJsonShallow = json.encode([
  {'id': 1, 'name': 'Top Dir 1', 'parent': null, 'order': 0},
  {'id': 2, 'name': 'Top Dir 2', 'parent': null, 'order': 1},
  {'id': 3, 'name': 'Bottom Dir 1', 'parent': 1, 'order': 0},
  {'id': 4, 'name': 'Bottom Dir 2', 'parent': 1, 'order': 1},
  {'id': 5, 'name': 'Bottom Dir 3', 'parent': 2, 'order': 0},
]);

final dirTreeJsonDeep = json.encode([
  {'id': 1, 'name': 'Top Dir 1', 'parent': null, 'order': 0},
  {'id': 2, 'name': 'Second Dir 1', 'parent': 1, 'order': 0},
  {'id': 3, 'name': 'Third Dir 1', 'parent': 2, 'order': 0},
  {'id': 4, 'name': 'Fourth Dir 1', 'parent': 3, 'order': 0},
  {'id': 5, 'name': 'Bottom Dir 1', 'parent': 4, 'order': 0},
]);

void main() {
  group('Model', () {
    test('Directory tree models are constructed from an empty json list', () {
      final tree = DirectoryTree.fromFolderList([]);
      expect(tree.directories.length, 0);
    });

    test('Directory tree models are constructed correctly from single json',
        () {
      final tree = DirectoryTree.fromFolderList(json.decode(dirTreeJsonSingle));
      expect(tree.directories.length, 1);
      expect(tree.directories.first.name, 'Top Dir 1');
    });

    test('Directory tree models are constructed correctly from flat json', () {
      final tree = DirectoryTree.fromFolderList(json.decode(dirTreeJsonFlat));
      expect(tree.directories.length, 3);
      expect(tree.directories.first.name, 'Top Dir 1');
      expect(tree.directories.last.name, 'Top Dir 3');
    });

    test('Directory tree models are constructed correctly from shallow json',
        () {
      final tree =
          DirectoryTree.fromFolderList(json.decode(dirTreeJsonShallow));
      expect(tree.directories.length, 2);
      expect(tree.directories.first.name, 'Top Dir 1');
      expect(tree.directories.last.name, 'Top Dir 2');

      var bottomDirs = tree.directories.first.children;
      expect(bottomDirs.length, 2);
      expect(bottomDirs.first.name, 'Bottom Dir 1');
      expect(bottomDirs.last.name, 'Bottom Dir 2');

      bottomDirs = tree.directories.last.children;
      expect(bottomDirs.length, 1);
      expect(bottomDirs.first.name, 'Bottom Dir 3');
    });

    test('Directory tree models are constructed correctly from deep json', () {
      final tree = DirectoryTree.fromFolderList(json.decode(dirTreeJsonDeep));

      expect(tree.directories.first.name, 'Top Dir 1');
      expect(tree.directories.first.children.first.name, 'Second Dir 1');
      expect(tree.directories.first.children.first.children.first.name,
          'Third Dir 1');
      expect(
          tree.directories.first.children.first.children.first.children.first
              .name,
          'Fourth Dir 1');
      expect(
          tree.directories.first.children.first.children.first.children.first
              .children.first.name,
          'Bottom Dir 1');
    });
  });
}
