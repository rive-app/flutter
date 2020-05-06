import 'package:meta/meta.dart';
import 'package:rive_api/src/data_model/data_model.dart';
import 'owner.dart';

class Team extends Owner {
  const Team({
    @required this.ownerId,
    @required this.name,
    @required this.username,
    @required this.permission,
    this.avatarUrl,
  });
  final int ownerId;
  final String name;
  final String username;
  final String avatarUrl;
  final String permission;

  static List<Team> fromDMList(List<TeamDM> teams) =>
      teams.map((team) => Team.fromDM(team)).toList();

  factory Team.fromDM(TeamDM team) => Team(
        ownerId: team.ownerId,
        name: team.name,
        username: team.username,
        permission: team.permission,
        avatarUrl: team.avatarUrl,
      );

  @override
  String toString() => 'Team($ownerId, $name)';

  @override
  bool operator ==(o) => o is Team && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;

  @override
  TeamDM get asDM => TeamDM(
        ownerId: ownerId,
        name: name,
        username: username,
        permission: permission,
        avatarUrl: avatarUrl,
      );
}
