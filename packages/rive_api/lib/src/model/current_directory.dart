import 'package:rive_api/model.dart';
import 'package:utilities/utilities.dart';

class CurrentDirectory {
  const CurrentDirectory(this.owner, this.folderId);
  final Owner owner;
  final int folderId;

  @override
  bool operator ==(Object o) =>
      o is CurrentDirectory &&
      o.folderId == folderId &&
      o.owner.ownerId == owner.ownerId;

  @override
  int get hashCode => szudzik(owner.ownerId, folderId);

  int get hashId => hashCode;

  @override
  String toString() =>
      'Folder: $folderId, owned by: $owner - ${owner.displayName}';
}
