import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/view_model/directory_tree.dart';

class VolumeVM {
  VolumeVM({this.id, this.name, this.avatarUrl, this.treeStream});
  final int id;
  final String name;
  final String avatarUrl;
  final Stream<DirectoryTreeVM> treeStream;

  factory VolumeVM.fromModel(Volume volume) => VolumeVM(
        id: volume.id,
        name: volume.name,
        avatarUrl: volume.avatarUrl,
      );

  factory VolumeVM.fromModelWithStream(
          Volume volume, Stream<DirectoryTreeVM> stream) =>
      VolumeVM(
        id: volume.id,
        name: volume.name,
        avatarUrl: volume.avatarUrl,
        treeStream: stream,
      );
}
