/// These view models are a mess
/// The tree should be properly converted
/// to use DirectoryVM. Seems like a bunch of
/// work to replicate the same structure ...
///
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

import 'package:rive_api/src/model/model.dart';

class DirectoryTreeVM {
  DirectoryTreeVM({this.tree, this.activeDirectory});
  final DirectoryTree tree;
  final DirectoryVM activeDirectory;

  factory DirectoryTreeVM.fromModel(DirectoryTree tree, [DirectoryVM dir]) =>
      DirectoryTreeVM(tree: tree, activeDirectory: dir);
}

class DirectoryVM extends Directory {
  DirectoryVM({
    @required int id,
    @required int ownerId,
    @required String name,
    Iterable<DirectoryVM> children,
  }) : super(id: id, name: name, ownerId: ownerId);

  factory DirectoryVM.fromModel(Directory d) => DirectoryVM(
      id: d.id,
      ownerId: d.ownerId,
      name: d.name,
      children: d.children.map((e) => DirectoryVM.fromModel(e)));

  static Directory toModel(DirectoryVM vmDir) => Directory(
      id: vmDir.id,
      ownerId: vmDir.ownerId,
      name: vmDir.name,
      children: vmDir.children?.map((e) => DirectoryVM.toModel(e)));

  bool modelEquals(Directory d) => this.id == d.id && this.ownerId == d.ownerId;

  @override
  String toString() => 'DirectoryVM($id, $name)';

  @override
  bool operator ==(o) =>
      (o is DirectoryVM || o is Directory) &&
      o.id == id &&
      this.ownerId == o.ownerId;

  @override
  int get hashCode => hash2(id, ownerId);
}
