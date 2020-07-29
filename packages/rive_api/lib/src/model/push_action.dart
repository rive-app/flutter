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
    } else if (action is TaskCompletedDM) {
      return TaskCompleted.fromDM(action);
    }
    throw Exception('unknown action $action');
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

class TaskCompleted extends PushAction {
  final Map<String, dynamic> attrs;
  final String taskId;

  TaskCompleted({this.taskId, this.attrs});

  factory TaskCompleted.fromDM(TaskCompletedDM action) {
    return TaskCompleted(
      taskId: action.taskId,
      attrs: action.attrs,
    );
  }
}
