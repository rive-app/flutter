import 'package:utilities/deserialize.dart';
import 'package:meta/meta.dart';
import 'owner.dart';

class TeamDM extends OwnerDM {
  const TeamDM({
    @required this.ownerId,
    @required this.name,
    @required this.username,
    @required this.permission,
    this.avatarUrl,
  });
  final int ownerId;
  final String name;
  final String username;
  final String avatarUrl;
  final String permission;

  static Iterable<TeamDM> fromDataList(List<dynamic> data) =>
      data.map((d) => TeamDM.fromData(d));

  factory TeamDM.fromData(Map<String, dynamic> data) => TeamDM(
        ownerId: data.getInt('ownerId'),
        name: data.getString('name'),
        username: data.getString('username'),
        avatarUrl: data.getString('avatar'),
        permission: data.getString('permission'),
      );

  @override
  String toString() => 'TeamDM($ownerId, $name)';

  @override
  bool operator ==(o) => o is TeamDM && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;
}
