import 'package:rive_api/owner.dart';

import 'src/deserialize_helper.dart';

class RiveUser extends RiveOwner {
  final int ownerId;
  final String username;
  final String name;
  final String avatar;
  final bool isAdmin;
  final bool isPaid;
  final int notificationCount;
  final bool isVerified;

  RiveUser({
    this.ownerId,
    this.username,
    this.name,
    this.avatar,
    this.isAdmin = false,
    this.isPaid = false,
    this.notificationCount = 0,
    this.isVerified = false,
  });

  @override
  String toString() {
    return 'RiveUser($ownerId, @$username, \'$name\')';
  }

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
}
