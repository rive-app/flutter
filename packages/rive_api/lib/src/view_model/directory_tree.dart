/// These view models are a mess
/// The tree should be properly converted
/// to use DirectoryVM. Seems like a bunch of
/// work to replicate the same structure ...
///
import 'package:meta/meta.dart';

import 'package:rive_api/src/model/model.dart';

class DirectoryTreeVM {
  DirectoryTreeVM({this.tree, this.activeDirectory});
  final DirectoryTree tree;
  final DirectoryVM activeDirectory;

  factory DirectoryTreeVM.fromModel(DirectoryTree tree, [DirectoryVM dir]) =>
      DirectoryTreeVM(tree: tree, activeDirectory: dir);
}

class DirectoryVM extends Directory {
  DirectoryVM(
      {@required int id, @required String name, Iterable<DirectoryVM> children})
      : super(id: id, name: name);

  factory DirectoryVM.fromModel(Directory d) =>
      DirectoryVM(id: d.id, name: d.name);

  static Directory toModel(DirectoryVM vmDir) =>
      Directory(id: vmDir.id, name: vmDir.name);

  bool modelEquals(Directory d) => this.id == d.id;

  @override
  String toString() => 'DirectoryVM($name)';

  @override
  bool operator ==(o) => (o is DirectoryVM || o is Directory) && o.id == id;

  @override
  int get hashCode => id;
}
