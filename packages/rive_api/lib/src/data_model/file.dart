import 'package:utilities/deserialize.dart';
import 'package:meta/meta.dart';
import 'cdn.dart';

class FileDM {
  FileDM({
    @required this.id,
    this.name,
    this.ownerId,
    this.preview,
  });
  final int id;
  final int ownerId;
  final String name;
  final String preview;

  static List<FileDM> fromDataList(List<dynamic> data, CdnDM cdn) =>
      data.map((d) => FileDM.fromData(d, cdn)).toList(growable: false);

  factory FileDM.fromData(Map<String, dynamic> data, CdnDM cdn) => FileDM(
        ownerId: data.getInt('ownerId'),
        name: data.getString('name'),
        preview: cdn.base + data.getString('preview') + cdn.params,
        id: data.getInt('id'),
      );

  static List<FileDM> fromIdList(List<dynamic> data, int ownerId) => data
      .map((id) => FileDM(id: id as int, ownerId: ownerId))
      .toList(growable: false);

  @override
  String toString() =>
      'File: $id - Name: ${name ?? 'No name yet'}, Owner: $ownerId';
}
