import 'package:rive_api/data_model.dart';
import 'package:rive_api/model.dart';

const meOwnerId = 40386;

MeDM getMe({int ownerId = 2}) {
  return MeDM(
      id: 1, ownerId: ownerId, signedIn: true, name: 'Max', username: 'max');
}

TeamDM getTeam({int ownerId = 3}) {
  return TeamDM(
      ownerId: ownerId,
      name: 'Team Titans',
      username: 'titans',
      permission: 'Owner',
      avatarUrl: null,
      status: 'ACTIVE');
}

FolderDM getFolder(OwnerDM owner) {
  return FolderDM(
    ownerId: (owner is MeDM) ? meOwnerId : owner.ownerId,
    name: 'My Folder',
    parent: 0,
    order: 0,
    id: 1,
  );
}

List<FolderDM> getFoldersDM(OwnerDM owner) {
  return [
    FolderDM(
      ownerId: (owner is MeDM) ? meOwnerId : owner.ownerId,
      name: 'Deleted Files',
      parent: null,
      order: 0,
      id: 0,
    ),
    FolderDM(
      ownerId: (owner is MeDM) ? meOwnerId : owner.ownerId,
      name: 'Your Files',
      parent: null,
      order: 0,
      id: 1,
    ),
  ];
}

CurrentDirectory getCurrentDirectory(Owner owner) {
  return CurrentDirectory(owner, 1);
}
