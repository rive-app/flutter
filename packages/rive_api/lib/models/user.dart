import 'package:meta/meta.dart';

import 'package:rive_api/owner.dart';
import 'package:rive_api/src/deserialize_helper.dart';

class RiveUser extends RiveOwner {
  final String username;
  final String avatar;
  final bool isAdmin;
  final bool isPaid;
  final int notificationCount;
  final bool isVerified;

  const RiveUser({
    @required int ownerId,
    @required String name,
    @required this.username,
    this.avatar,
    this.isAdmin = false,
    this.isPaid = false,
    this.notificationCount = 0,
    this.isVerified = false,
  }) : super(id: ownerId, name: name);

  factory RiveUser.fromData(Map<String, dynamic> data,
      {bool requireSignin = true}) {
    if (requireSignin && !data.getBool('signedIn')) {
      return null;
    }

    return RiveUser(
      ownerId: data.getInt('ownerId'),
      username: data.getString('username'),
      name: data.getString('name'),
      avatar: data.getString('avatar'),
      isAdmin: data.getBool('isAdmin'),
      isPaid: data.getBool('isPaid'),
      notificationCount: data.getInt('notificationCount'),
      isVerified: data.getBool('verified'),
    );
  }

  @override
  String toString() => 'RiveUser($ownerId, @$username, \'$name\')';
}
