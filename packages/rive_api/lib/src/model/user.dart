import 'package:meta/meta.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/data_model.dart';

import 'owner.dart';

class User extends Owner {
  const User({
    @required int ownerId,
    @required String name,
    @required String username,
    @required String avatarUrl,
  }) : super(ownerId, name, username, avatarUrl);

  static List<User> fromDMList(List<UserDM> users) =>
      users.map((user) => User.fromDM(user)).toList();

  factory User.fromDM(UserDM user) => User(
        ownerId: user.ownerId,
        name: user.name,
        username: user.username,
        avatarUrl: user.avatarUrl,
      );

  @override
  String toString() => 'User($ownerId, $name)';

  @override
  bool operator ==(Object o) => o is User && o.ownerId == ownerId;

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

class TeamMember extends Owner {
  const TeamMember({
    @required int ownerId,
    @required String name,
    @required String username,
    @required String avatarUrl,
    @required this.status,
    @required this.permission,
  }) : super(ownerId, name, username, avatarUrl);

  final String status;
  final TeamRole permission;

  static List<TeamMember> fromDMList(List<TeamMemberDM> teamMembers) =>
      teamMembers.map((teamMember) => TeamMember.fromDM(teamMember)).toList();

  factory TeamMember.fromDM(TeamMemberDM teamMember) => TeamMember(
        ownerId: teamMember.ownerId,
        name: teamMember.name,
        username: teamMember.username,
        avatarUrl: teamMember.avatarUrl,
        status: teamMember.status,
        permission: TeamRoleExtension.teamRoleFromString(teamMember.permission),
      );

  @override
  String toString() => 'TeamMember($ownerId, $name)';

  @override
  bool operator ==(Object o) => o is TeamMember && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;

  @override
  TeamMemberDM get asDM => TeamMemberDM(
        ownerId: ownerId,
        name: name,
        username: username,
        avatarUrl: avatarUrl,
        status: status,
        permission: permission.toString(),
      );
}
