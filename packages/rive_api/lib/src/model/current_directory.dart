import 'package:rive_api/src/model/model.dart';

class CurrentDirectory {
  const CurrentDirectory(this.owner, this.folderId);
  final Owner owner;
  final int folderId;

  @override
  String toString() =>
      'Folder: $folderId, owned by: $owner - ${owner.displayName}';
}
