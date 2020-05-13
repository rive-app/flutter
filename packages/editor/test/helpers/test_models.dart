import 'package:rive_api/model.dart';
import 'package:rive_api/models/team_role.dart';

CurrentDirectory getCurrentDirectory({Owner owner, int folderId = 1}) {
  var _owner = owner;
  if (owner == null) {
    _owner = getOwner();
  }
  return CurrentDirectory(_owner, folderId);
}

Owner getOwner({int ownerId = 1}) {
  return Team(
    ownerId: ownerId,
    username: 'TeamUsername',
    name: 'Name',
    permission: TeamRole.admin,
  );
}
