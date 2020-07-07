/// Tree of directories
import 'package:rive_api/data_model.dart';

abstract class PushAction {
  static PushAction fromDM(PushActionDM action) {
    if (action is NewNotificationDM) {
      return NewNotification();
    } else if (action is PingNotificationDM) {
      return PingNotification();
    } else if (action is FolderNotificationDM) {
      return FolderNotification.fromDM(action);
    }
    throw Exception('unkown action $action');
  }
}

class NewNotification extends PushAction {}

class PingNotification extends PushAction {}

class FolderNotification extends PushAction {
  final int folderOwnerId;
  final int folderId;

  FolderNotification(this.folderOwnerId, this.folderId);

  factory FolderNotification.fromDM(FolderNotificationDM action) {
    return FolderNotification(action.folderOwnerId, action.folderId);
  }
}
