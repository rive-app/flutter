import 'package:meta/meta.dart';
import 'package:utilities/deserialize.dart';

enum VolumeType { user, team }

class Volume {
  const Volume({@required this.name, this.id, this.avatarUrl})
      : assert(name != null);
  final int id;
  final String name;
  final String avatarUrl;

  bool get hasAvatar => avatarUrl != null;

  /// If the volume's id is null, then it's a user volume
  VolumeType get type => id == null ? VolumeType.user : VolumeType.team;

  factory Volume.fromData(Map<String, dynamic> data) => Volume(
        id: data.getInt('id'),
        name: data.getString('name'),
        avatarUrl: data.getString('avatar'),
      );

  /// Returns a list of volumes from a JSON document
  static Iterable<Volume> fromDataList(List<dynamic> dataList) =>
      dataList.map((data) => Volume.fromData(data));

  @override
  String toString() => 'Volume($name)';
}
