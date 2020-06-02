import 'package:utilities/deserialize.dart';

/// Data model representing a single revision for a file.
class RevisionDM {
  /// Id is unique to the file this revision was loaded for, if you're looking
  /// for a globally unique identifier, look at the [key].
  final int id;

  /// Key for the revision data stored in S3.
  final String key;

  /// Time the revision file was last updated.
  final DateTime updated;

  /// Name given to the revision file (most will be null).
  final String name;

  RevisionDM({this.id, this.key, this.updated, this.name});

  static List<RevisionDM> fromDataList(List<Map<String, dynamic>> dataList) =>
      dataList
          .map<RevisionDM>((data) => RevisionDM.fromData(data))
          .toList(growable: false);

  factory RevisionDM.fromData(Map<String, dynamic> data) {
    int id = data.getInt('id');
    if (id == null) {
      return null;
    }

    var updated = data.getInt('updated');
    return RevisionDM(
      id: id,
      key: data.getString('key'),
      updated: updated == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updated * 1000),
      name: data.getString('name'),
    );
  }
}
