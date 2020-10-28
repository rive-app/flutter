import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import 'package:rive_api/models/owner.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/models/team_invite_status.dart';
import 'package:utilities/deserialize.dart';

class RiveUser extends RiveOwner {
  final bool isAdmin;
  final bool isPaid;
  final int notificationCount;
  final bool isVerified;
  final TeamInviteStatus status;
  final TeamRole role;

  RiveUser(
      {@required int ownerId,
      @required String name,
      @required String username,
      String avatar,
      this.isAdmin = false,
      this.isPaid = false,
      this.notificationCount = 0,
      this.isVerified = false,
      this.status,
      this.role})
      : assert(ownerId != null),
        assert(name != null || username != null),
        super(id: ownerId, name: name, username: username, avatar: avatar);

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
        isVerified: data.getBool('verified'));
  }

  factory RiveUser.fromAutoCompleteData(Map<String, dynamic> data) {
    return RiveUser(
      ownerId: data.getInt('i'),
      username: data.getString('n'),
      name: data.getString('l'),
      avatar: data.getString('a'),
    );
  }

  factory RiveUser.asTeamMember(Map<String, dynamic> data) {
    return RiveUser(
      ownerId: data.getInt('ownerId'),
      name: data.getString('name'),
      username: data.getString('username'),
      status: data.getInvitationStatus(),
      role: data.getTeamRole(),
    );
  }

  @override
  String toString() => 'RiveUser($ownerId, @$username, \'$name\')';
}
