import 'package:utilities/deserialize.dart';

abstract class PushActionDM {
  static PushActionDM fromData(Map<String, dynamic> data) {
    if (!data.containsKey("action")) {
      return null;
    }
    switch (data["action"] as String) {
      case 'NewNotification':
        return NewNotificationDM();
      case 'Ping':
        return PingNotificationDM();
      case 'FolderChange':
        return FolderNotificationDM.fromData(data);
      default:
        throw Exception('Unknown action $data');
    }
  }
}

class NewNotificationDM extends PushActionDM {}

class PingNotificationDM extends PushActionDM {}

class FolderNotificationDM extends PushActionDM {
  final int folderOwnerId;
  final int folderId;

  FolderNotificationDM({this.folderOwnerId, this.folderId});

  factory FolderNotificationDM.fromData(Map<String, dynamic> data) {
    var params = data.getMap<String, Object>('params');
    return FolderNotificationDM(
      folderOwnerId: params.getInt('folderOwnerId'),
      folderId: params.getInt('folderId'),
    );
  }
}
