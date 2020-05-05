/// This view model embeds the directory tree
/// stream in it, making it easy to access in the UI.
/// The vm has no logic or control, as it's instantiated
/// and managed by the volume manager, so this might be a nice
/// way to keep concerns separated while not having a bunch of
/// disconnected streams coming out of managers.
///
/// Also a nice example of where we extend the data model with
/// useful data for the ui.

import 'package:rive_api/src/model/model.dart';
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';
import 'package:rive_api/src/view_model/view_model.dart';
import 'package:rxdart/subjects.dart';

class FileVM {
  FileVM({
    @required this.id,
    @required this.name,
    @required this.ownerId,
  });
  final int id;
  final String name;
  final int ownerId;

  factory FileVM.fromModel(File file) => FileVM(
        id: file.id,
        name: file.name,
        ownerId: file.ownerId,
      );

  @override
  String toString() => 'File($name:$ownerId)';

  @override
  bool operator ==(o) => o is FileVM && o.id == id && o.ownerId == ownerId;

  @override
  int get hashCode => hash2(id, ownerId);
}
