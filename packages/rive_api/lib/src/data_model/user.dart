import 'package:utilities/deserialize.dart';
import 'package:meta/meta.dart';
import 'owner.dart';

class UserDM extends OwnerDM {
  const UserDM({
    @required this.ownerId,
    @required this.name,
    @required this.username,
    @required this.avatarUrl,
  });
  final int ownerId;
  final String name;
  final String username;
  final String avatarUrl;

  static Iterable<UserDM> fromSearchDataList(List<dynamic> data) =>
      data.map((d) => UserDM.fromSearchData(d));

  factory UserDM.fromSearchData(Map<String, dynamic> data) => UserDM(
        ownerId: data.getInt('i'),
        name: data.getString('l'),
        username: data.getString('n'),
        avatarUrl: data.getString('a'),
      );

  @override
  String toString() => 'UserDM($ownerId, $name)';

  @override
  bool operator ==(o) => o is UserDM && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;
}
