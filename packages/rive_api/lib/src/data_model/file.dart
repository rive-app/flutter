import 'package:utilities/deserialize.dart';
import 'package:meta/meta.dart';
import 'cdn.dart';

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

  static Iterable<File> fromDataList(List<dynamic> data, CDN cdn) =>
      data.map((d) => File.fromData(d, cdn));

  factory File.fromData(Map<String, dynamic> data, CDN cdn) => File(
        ownerId: data.getInt('ownerId'),
        name: data.getString('name'),
        preview: cdn.base + data.getString('preview') + cdn.params,
        id: data.getInt('id'),
      );

  static Iterable<File> fromIdList(List<dynamic> data, int ownerId) =>
      data.map((id) => File(id: id as int, ownerId: ownerId));
}
