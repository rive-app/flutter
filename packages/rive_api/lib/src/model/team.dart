import 'package:meta/meta.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/data_model.dart';
import 'owner.dart';

class Team extends Owner {
  const Team({
    @required int ownerId,
    @required String name,
    @required String username,
    @required this.permission,
    String avatarUrl,
  }) : super(ownerId, name, username, avatarUrl);

  final TeamRole permission;

  static List<Team> fromDMList(List<TeamDM> teams) =>
      teams.map((team) => Team.fromDM(team)).toList();

  factory Team.fromDM(TeamDM team) => Team(
        ownerId: team.ownerId,
        name: team.name,
        username: team.username,
        permission: TeamRoleExtension.teamRoleFromString(team.permission),
        avatarUrl: team.avatarUrl,
      );

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
      );
}
