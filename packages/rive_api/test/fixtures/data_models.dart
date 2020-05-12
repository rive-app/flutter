import 'package:rive_api/src/data_model/data_model.dart';

MeDM getMe() {
  return MeDM(id: 1, ownerId: 2, signedIn: true, name: 'Max', username: 'max');
}

TeamDM getTeam() {
  return TeamDM(
      ownerId: 3, name: 'Team Titans', username: 'titans', permission: 'Owner');
}

FolderDM getFolder(OwnerDM owner) {
  return FolderDM(
    ownerId: (owner is MeDM) ? null : owner.ownerId,
    name: 'My Folder',
    parent: 0,
    order: 0,
    id: 1,
  );
}
