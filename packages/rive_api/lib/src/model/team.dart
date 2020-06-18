import 'package:meta/meta.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/data_model.dart';
import 'owner.dart';

enum TeamStatus { active, failedPayment, suspended }

extension TeamStatusExtension on TeamStatus {
  static TeamStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return TeamStatus.active;
      case 'suspended':
        return TeamStatus.suspended;
      case 'failed_payment':
        return TeamStatus.failedPayment;
      default:
        return null;
    }
  }
}

class Team extends Owner {
  const Team({
    @required int ownerId,
    @required String name,
    @required String username,
    @required this.permission,
    @required this.status,
    String avatarUrl,
  }) : super(ownerId, name, username, avatarUrl);

  final TeamRole permission;
  final TeamStatus status;

  static List<Team> fromDMList(List<TeamDM> teams) =>
      teams.map((team) => Team.fromDM(team)).toList();

  factory Team.fromDM(TeamDM team) => Team(
      ownerId: team.ownerId,
      name: team.name,
      username: team.username,
      permission: TeamRoleExtension.teamRoleFromString(team.permission),
      avatarUrl: team.avatarUrl,
      status: TeamStatusExtension.fromString(team.status));

  @override
  String toString() => 'Team($ownerId, $name)';

  @override
  bool operator ==(Object o) => o is Team && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;

  @override
  TeamDM get asDM => TeamDM(
      ownerId: ownerId,
      name: name,
      username: username,
      permission: permission.toString(),
      avatarUrl: avatarUrl,
      status: status.toString());
}
