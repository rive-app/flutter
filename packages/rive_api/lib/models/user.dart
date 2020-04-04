import 'package:meta/meta.dart';

import 'package:rive_api/models/owner.dart';
import 'package:rive_api/src/deserialize_helper.dart';

enum TeamInviteStatus { accepted, pending }
enum TeamRole { member, admin }

class RiveUser extends RiveOwner {
  final String avatar;
  final bool isAdmin;
  final bool isPaid;
  final int notificationCount;
  final bool isVerified;
  final TeamInviteStatus status;
  final TeamRole role;

  RiveUser({
    @required int ownerId,
    @required String name,
    @required String username,
    this.avatar,
    this.isAdmin = false,
    this.isPaid = false,
    this.notificationCount = 0,
    this.isVerified = false,
    this.status,
    this.role,
  })  : assert(ownerId != null),
        assert(name != null || username != null),
        super(id: ownerId, name: name, username: username);

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

  factory RiveUser.fromAutoCompleteData(Map<String, dynamic> data) {
    return RiveUser(
      ownerId: data.getInt('i'),
      username: data.getString('n'),
      name: data.getString('l'),
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

extension DeserializeHelper on Map<String, dynamic> {
  TeamInviteStatus getInvitationStatus() {
    dynamic value = this['status'];
    switch (value) {
      case 'pending':
        return TeamInviteStatus.pending;
      case 'complete':
        return TeamInviteStatus.accepted;
      default:
        return TeamInviteStatus.pending;
    }
  }

  TeamRole getTeamRole() {
    dynamic value = this['permission'];
    switch (value) {
      case 'admin':
        return TeamRole.admin;
      case 'member':
        return TeamRole.member;
      default:
        return TeamRole.member;
    }
  }
}