import 'package:meta/meta.dart';
import 'package:quiver/core.dart';
import 'package:rive_api/data_model.dart';

class File {
  File({
    @required this.id,
    this.name,
    int ownerId,
    this.fileOwnerId,
    this.preview,
  }) : _ownerId = ownerId;

  final int id;
  final int _ownerId;
  // TODO: teams and projects play funny games wiht us here
  // teams do not own their own files, projects do.
  // once we have projects in our front end, we can hopefully
  // remove this nonsense.
  final int fileOwnerId;
  final String name;
  final String preview;

  static List<File> fromDMList(List<FileDM> files, [int altOwnerId]) =>
      files.map((file) => File.fromDM(file, altOwnerId)).toList();

  factory File.fromDM(FileDM file, [int altOwnerId]) => File(
        ownerId: altOwnerId,
        fileOwnerId: file.ownerId,
        name: file.name,
        preview: file.preview,
        id: file.id,
      );

  int get ownerId => _ownerId ?? fileOwnerId;

  @override
  bool operator ==(o) => o is File && o.id == id && o.ownerId == ownerId;

  @override
  int get hashCode => hash2(id, ownerId);

  @override
  String toString() => '< File: $name - Id: $id. Owner: $ownerId >';
}
