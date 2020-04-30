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
import 'package:meta/meta.dart';

enum VolumeType { user, team }

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
  VolumeVM({
    @required this.id,
    @required this.name,
    @required this.treeStream,
    @required this.type,
    this.avatarUrl,
  });
  final int id;
  final String name;
  final String avatarUrl;
  final Stream<DirectoryTreeVM> treeStream;
  final VolumeType type;

  factory VolumeVM.fromMeModel(Me me, Stream<DirectoryTreeVM> stream) =>
      VolumeVM(
        type: VolumeType.user,
        id: me.ownerId,
        name: me.name,
        avatarUrl: me.avatarUrl,
        treeStream: stream,
      );

  factory VolumeVM.fromTeamModel(Team team, Stream<DirectoryTreeVM> stream) =>
      VolumeVM(
        type: VolumeType.team,
        id: team.ownerId,
        name: team.name,
        avatarUrl: team.avatarUrl,
        treeStream: stream,
      );

  @override
  String toString() => 'VolumeVM($name)';

  @override
  bool operator ==(o) => o is VolumeVM && o.id == id;

  @override
  int get hashCode => id;
}
