import 'package:meta/meta.dart';
import 'package:rive_api/data_model.dart';
import 'named.dart';

class File implements Named {
  File({
    @required this.id,
    this.name,
    int ownerId,
    this.fileOwnerId,
    this.thumbnail,
  }) : _ownerId = ownerId;

  final int id;
  final int _ownerId;
  // TODO: teams and projects play funny games with us here
  // teams do not own their own files, projects do.
  // once we have projects in our front end, we can hopefully
  // remove this nonsense.
  final int fileOwnerId;
  @override
  final String name;
  final String thumbnail;

  static List<File> fromDMList(Iterable<FileDM> files, [int altOwnerId]) =>
      files.map((file) => File.fromDM(file, altOwnerId)).toList();

  factory File.fromDM(FileDM file, [int altOwnerId]) => File(
        ownerId: altOwnerId,
        fileOwnerId: file.ownerId,
        name: file.name,
        thumbnail: file.thumbnail,
        id: file.id,
      );

  int get ownerId => _ownerId ?? fileOwnerId;

  @override
  bool operator ==(Object o) => o is File && o.id == id;

  @override
  int get hashCode => id;

  @override
  String toString() => '< File: $name - Id: $id. Owner: $ownerId >';
}
