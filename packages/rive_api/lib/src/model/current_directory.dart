import 'package:rive_api/model.dart';
import 'package:utilities/utilities.dart';

class CurrentDirectory {
  const CurrentDirectory(this.owner, this.folderId);
  final Owner owner;
  final int folderId;

  @override
  bool operator ==(o) =>
      o is CurrentDirectory &&
      o.folderId == folderId &&
      o.owner.ownerId == owner.ownerId;

  int get hashId => szudzik(owner.ownerId, folderId);

  @override
  String toString() =>
      'Folder: $folderId, owned by: $owner - ${owner.displayName}';
}
