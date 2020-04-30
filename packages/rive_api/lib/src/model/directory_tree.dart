/// Tree of directories
import 'package:meta/meta.dart';
import 'package:utilities/deserialize.dart';

class DirectoryTree {
  DirectoryTree({this.directories = const []});
  final Iterable<Directory> directories;

  bool get isEmpty => directories.isEmpty;

  /// Creates a directory tree from a json list
  factory DirectoryTree.fromFolderList(List<dynamic> data) {
    // Check whether the list is empty
    if (data.isEmpty) {
      return DirectoryTree();
    }
    // Read through every directory and sort them into child lists
    // 0 is a special case parent id; means the directory is top level
    final sortedData = <int, List<Map<String, dynamic>>>{};
    data.forEach((dir) {
      final parentId = (dir as Map<String, dynamic>).getInt('parent');
      if (!sortedData.containsKey(parentId)) {
        sortedData[parentId] = <Map<String, dynamic>>[];
      }
      sortedData[parentId].add(dir);
    });
    // Build the tree structure from the top down
    return DirectoryTree(
      directories: sortedData[0].map(
        (dirData) => _createDirectory(dirData, sortedData),
      ),
    );
  }

  /// Recursely builds a tree of directories
  static Directory _createDirectory(
    Map<String, dynamic> directoryData,
    Map<int, List<Map<String, dynamic>>> sortedChildrenData,
  ) {
    final directoryId = directoryData.getInt('id');
    assert(directoryId != null);
    // Create the children
    final children = (sortedChildrenData[directoryId] ?? []).map<Directory>(
        (childData) => _createDirectory(childData, sortedChildrenData));
    return Directory.fromData(directoryData, children: children);
  }

  /// Does the tree contain the specified directory?
  bool contains(Directory dir) {
    for (final d in walk) {
      if (d == dir) {
        return true;
      }
    }
    return false;
  }

  /// Walks all directories in the tree(s)
  Iterable<Directory> get walk sync* {
    for (final dir in directories) {
      yield* _treeWalk(dir);
    }
  }

  /// Internal generator to walk a tree
  Iterable<Directory> _treeWalk(Directory d) sync* {
    for (final child in d.children) {
      yield* _treeWalk(child);
    }
    yield d;
  }
}

class Directory {
  Directory({@required this.id, @required this.name, this.children});
  final int id;
  final String name;
  final Iterable<Directory> children;

  factory Directory.fromData(Map<String, dynamic> data,
          {Iterable<Directory> children}) =>
      Directory(
        id: data.getInt('id'),
        name: data.getString('name'),
        children: children ?? [],
      );

  @override
  String toString() => 'Directory($name)';

  @override
  bool operator ==(o) => o is Directory && o.id == id;

  @override
  int get hashCode => id;
}
