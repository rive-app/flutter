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
      default:
        throw Exception('Unknown action $data');
    }
  }
}

class NewNotificationDM extends PushActionDM {}

class PingNotificationDM extends PushActionDM {}
