import 'dart:collection';

/// Tree of directories
import 'package:meta/meta.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_api/model.dart';
import 'package:rxdart/subjects.dart';

class FolderTree {
  FolderTree({
    @required this.owner,
    @required this.root,
  });
  final Owner owner;
  final FolderTreeItem root;

  factory FolderTree.fromOwner(Owner owner) {
    return FolderTree(owner: owner, root: FolderTreeItem.placeholder(owner));
  }

  factory FolderTree.fromFolderList(Owner owner, List<Folder> folders) {
    // Turn folders into tree items.
    var treeItems = folders
        .map((folder) => FolderTreeItem(folder: folder, owner: owner))
        .toList();

    // Build folder id => folder lookup table.
    var lookup = HashMap<int, FolderTreeItem>();
    for (final treeItem in treeItems) {
      lookup[treeItem.folder.id] = treeItem;
    }

    // Parent the tree items.
    for (final treeItem in treeItems) {
      var parentTreeItem = lookup[treeItem.folder.parent];
      if (parentTreeItem != null) {
        parentTreeItem.children.add(treeItem);
      }
    }

    return FolderTree(
      owner: owner,
      root: treeItems.firstWhere(
        (item) => item.folder.isRoot,
      ),
    );
  }
}

class FolderTreeItem {
  FolderTreeItem({@required this.folder, this.owner}) {
    hover = false;

    final currentDirectory = Plumber().peek<CurrentDirectory>();
    if (currentDirectory != null &&
        (currentDirectory.folder?.id == folder?.id &&
            currentDirectory.owner == owner)) {
      selected = true;
    } else {
      selected = false;
    }
  }

  final Folder folder;
  final _hover = BehaviorSubject<bool>();
  final _selected = BehaviorSubject<bool>();
  final Owner owner;
  final List<FolderTreeItem> children = [];

  String get iconURL {
    return owner?.avatarUrl;
  }

  String get name => folder.name ?? owner.displayName;
  bool get isRoot => folder.isRoot;

  BehaviorSubject<bool> get hoverStream => _hover;
  BehaviorSubject<bool> get selectedStream => _selected;
  bool get selected => _selected.value == true;
  bool get hover => _hover.value == true;

  set selected(bool value) {
    if (selected != value) {
      _selected.add(value);
    }
  }

  set hover(bool value) {
    if (hover != value) {
      _hover.add(value);
    }
  }

  // Placeholder used until the real data set is loaded.
  factory FolderTreeItem.placeholder(Owner owner) {
    return FolderTreeItem(
      folder: Folder.root(owner),
      owner: owner,
    );
  }
}
