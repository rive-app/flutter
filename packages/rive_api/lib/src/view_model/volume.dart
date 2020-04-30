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
import 'package:rive_api/src/view_model/directory_tree.dart';

/// We could inherit from the data model as it shares some data,
/// but I like the fact that this is readable without reference
/// elsewhere.
///
/// We could also compose the data model into the view model, as
/// they're both immutable:
///
/// class VolumeVM2 {
///   VolumeVM2({this.model, this.treeStream});
///   final Volume model;
///   int get id => model.id;
///   String get name => name;
///   String get avatarUrl => avatarUrl;
///   ...
/// }
class VolumeVM {
  VolumeVM({this.id, this.name, this.avatarUrl, this.treeStream});
  final int id;
  final String name;
  final String avatarUrl;
  final Stream<DirectoryTreeVM> treeStream;

  factory VolumeVM.fromModel(Volume volume, Stream<DirectoryTreeVM> stream) =>
      VolumeVM(
        id: volume.id,
        name: volume.name,
        avatarUrl: volume.avatarUrl,
        treeStream: stream,
      );
}
