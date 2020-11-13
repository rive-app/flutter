import 'package:meta/meta.dart';
import 'package:rive_api/models/team_invite_status.dart';
import 'package:utilities/deserialize.dart';

import 'owner.dart';

class UserDM extends OwnerDM {
  const UserDM({
    @required int ownerId,
    @required String name,
    @required String username,
    @required this.avatarUrl,
  }) : super(ownerId, name, username);

  final String avatarUrl;

  static Iterable<UserDM> fromSearchDataList(List<Map<String, dynamic>> data) =>
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
  bool operator ==(Object o) => o is UserDM && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;
}

class TeamMemberDM extends OwnerDM {
  final bool free;
  const TeamMemberDM({
    @required int ownerId,
    @required String name,
    @required String username,
    @required this.avatarUrl,
    @required this.status,
    @required this.permission,
    @required this.free,
  }) : super(ownerId, name, username);

  final String avatarUrl;
  final TeamInviteStatus status;
  final String permission;

  static Iterable<TeamMemberDM> formDataList(List<Map<String, dynamic>> data) =>
      data.map((d) => TeamMemberDM.formData(d));

  factory TeamMemberDM.formData(Map<String, dynamic> data) => TeamMemberDM(
        ownerId: data.getInt('ownerId'),
        name: data.getString('name'),
        username: data.getString('username') ?? data.getString('email'),
        avatarUrl: data.getString('avatar'),
        permission: data.getString('permission'),
        free: data.getBool('free'),
        status: data.getInvitationStatus(),
      );

  @override
  String toString() => 'TeamMember($ownerId, $name)';

  @override
  bool operator ==(Object o) => o is TeamMemberDM && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;
}
