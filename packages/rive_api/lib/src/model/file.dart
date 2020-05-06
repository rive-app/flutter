import 'package:meta/meta.dart';
import 'package:quiver/core.dart';
import 'package:rive_api/src/data_model/data_model.dart';

class File {
  File({
    @required this.id,
    this.name,
    this.ownerId,
    this.preview,
  });
  final int id;
  final int ownerId;
  final String name;
  final String preview;

  static List<File> fromDMList(List<FileDM> files) =>
      files.map((file) => File.fromDM(file)).toList();

  factory File.fromDM(FileDM file) => File(
        ownerId: file.ownerId,
        name: file.name,
        preview: file.preview,
        id: file.id,
      );

  @override
  bool operator ==(o) => o is File && o.id == id && o.ownerId == ownerId;

  @override
  int get hashCode => hash2(id, ownerId);
}
