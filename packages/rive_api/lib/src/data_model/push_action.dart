import 'package:utilities/deserialize.dart';

abstract class PushActionDM {
  static PushActionDM fromData(Map<String, dynamic> data) {
    if (!data.containsKey('action')) {
      return null;
    }
    switch (data['action'] as String) {
      case 'NewNotification':
        return NewNotificationDM();
      case 'Ping':
        return PingNotificationDM();
      case 'FolderChange':
        return FolderNotificationDM.fromData(data);
      case 'TaskCompleted':
        return TaskCompletedDM.fromData(data);
      case 'TaskFailed':
        return TaskCompletedDM.fromData(data);
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

class TaskCompletedDM extends PushActionDM {
  final Map<String, dynamic> attrs;
  final String taskId;
  final bool success;

  TaskCompletedDM({this.taskId, this.attrs, this.success});

  factory TaskCompletedDM.fromData(Map<String, dynamic> data) {
    var params = data.getMap<String, Object>('params');
    return TaskCompletedDM(
      taskId: params.getString('taskId'),
      attrs: data,
      success: data['action'] == 'TaskCompleted',
    );
  }
}
