import 'package:rive_api/model.dart';
import 'package:utilities/utilities.dart';

class CurrentDirectory {
  const CurrentDirectory(this.owner, this.folder);
  final Owner owner;

  final Folder folder;

  @override
  bool operator ==(Object o) =>
      o is CurrentDirectory &&
      o.folder?.id == folder?.id &&
      o.owner.ownerId == owner.ownerId;

  @override
  int get hashCode => szudzik(owner.ownerId, folder?.id ?? 0);

  int get hashId => hashCode;

  @override
  String toString() =>
      'Folder: ${folder?.id}, owned by: $owner - ${owner.displayName}';
}
