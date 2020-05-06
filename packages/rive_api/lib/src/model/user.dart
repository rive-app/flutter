import 'package:meta/meta.dart';
import 'package:rive_api/src/data_model/data_model.dart';
import 'owner.dart';

class User extends Owner {
  const User({
    @required this.ownerId,
    @required this.name,
    @required this.username,
    @required this.avatarUrl,
  });
  final int ownerId;
  final String name;
  final String username;
  final String avatarUrl;

  static Iterable<User> fromDMList(List<UserDM> users) =>
      users.map((user) => User.fromDM(user));

  factory User.fromDM(UserDM user) => User(
        ownerId: user.ownerId,
        name: user.name,
        username: user.username,
        avatarUrl: user.avatarUrl,
      );

  @override
  String toString() => 'User($ownerId, $name)';

  @override
  bool operator ==(o) => o is User && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;

  @override
  UserDM get asDM => UserDM(
        ownerId: ownerId,
        name: name,
        username: username,
        avatarUrl: avatarUrl,
      );
}
