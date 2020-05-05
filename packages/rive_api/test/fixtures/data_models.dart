import 'package:rive_api/src/data_model/data_model.dart';

Me getMe() {
  return Me(id: 1, ownerId: 2, signedIn: true, name: 'Max', username: 'max');
}

Team getTeam() {
  return Team(
      ownerId: 3, name: 'Team Titans', username: 'titans', permission: 'Owner');
}

Folder getFolder(Owner owner) {
  return Folder(
    ownerId: (owner is Me) ? null : owner.ownerId,
    name: 'My Folder',
    parent: 0,
    order: 0,
    id: 1,
  );
}
