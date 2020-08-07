import 'package:utilities/utilities.dart';
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

  static List<FileDM> fromDataList(
          List<Map<String, dynamic>> data, CdnDM cdn) =>
      data.map((d) => FileDM.fromData(d, cdn)).toList(growable: false);

  factory FileDM.fromData(Map<String, dynamic> data, CdnDM cdn) {
    return FileDM(
      ownerId: data.getInt('oid'),
      name: data.getString('name'),
      preview: (data.getString('preview') == null)
          ? null
          : cdn.base + data.getString('preview') + cdn.params,
      id: data.getInt('id'),
    );
  }

  factory FileDM.fromCreateData(
    Map<String, dynamic> data,
  ) {
    return FileDM(
      ownerId: data.getInt('oid'),
      name: data.getString('name'),
      id: data.getInt('id'),
    );
  }

  static List<FileDM> fromIdList(
    List<int> data,
    int ownerId,
  ) =>
      data
          .map((id) => FileDM(id: id, ownerId: ownerId))
          .toList(growable: false);

  /// Returns an iterable of file data models from hashed ids of
  /// ownerId, fileId. Order is fileId, ownerId
  static Iterable<FileDM> fromHashedIdList(List<String> hashedIds) =>
      hashedIds.map<FileDM>((hashedId) {
        final ids = decodeIds(hashedId);
        assert(ids.length == 2);
        return FileDM(id: ids[0], ownerId: ids[1]);
      });

  // Returns an iterable of files from a list of json maps
  // representing the files, which use a hashed id
  static Iterable<FileDM> fromHashedIdDataList(
          List<Map<String, dynamic>> data) =>
      data.map((d) => FileDM.fromHashedIdData(d)).toList(growable: false);

  // Creates a file from json which uses a hashed id
  factory FileDM.fromHashedIdData(Map<String, dynamic> data) {
    final ids = decodeIds(data.getString('id'));
    assert(ids.length == 2);
    return FileDM(
      id: ids[0],
      ownerId: ids[1],
      name: data.getString('name'),
      // we need the cdn deatils to do preview 'properly'
      // preview: data.getString('preview'),
    );
  }

  @override
  String toString() =>
      'File: $id - Name: ${name ?? 'No name yet'}, Owner: $ownerId';
}
