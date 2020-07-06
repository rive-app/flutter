/// Tree of directories
import 'package:rive_api/data_model.dart';

abstract class PushAction {
  static PushAction fromDM(PushActionDM action) {
    if (action is NewNotificationDM) {
      return NewNotification();
    } else if (action is PingNotificationDM) {
      return PingNotification();
    }
    throw Exception('unkown action $action');
  }
}

class NewNotification extends PushAction {}

class PingNotification extends PushAction {}
