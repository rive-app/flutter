import 'dart:convert';
import 'package:core/web_socket/web_socket.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart' as model;
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/managers/notification_manager.dart';

/// General manager for general ui things
class WebsocketCommsManager with Subscriptions {
  static final WebsocketCommsManager _instance = WebsocketCommsManager._();
  factory WebsocketCommsManager() => _instance;

  WebsocketCommsManager._() {
    _attach();
  }

  /// Initiatize the state
  void _attach() {
    /// When the logged in user is changed, fetch notifications for the new user
    subscribe<model.Me>((_) => _connect());
  }

  Future<void> _connect() async {
    await _client?.disconnect();
    final me = Plumber().peek<model.Me>();
    if (me == null || me.isEmpty) {
      return;
    }
    _client = CommsWebsocketClient(
        'wss://slimer-web.rive.app/max_test', handleAction);
    await _client.connect();
  }

  void handleAction(PushAction action) {
    if (action is model.NewNotification) {
      NotificationManager().update();
    } else if (action is model.PingNotification) {
      print('We were pinged');
    }
  }

  ReconnectingWebsocketClient _client;
}

class CommsWebsocketClient extends ReconnectingWebsocketClient {
  MeApi _meAPI;
  Function(PushAction) callback;
  CommsWebsocketClient(String url, this.callback) : super(url) {
    _meAPI = MeApi();
  }

  @override
  Future<void> onConnect() async {
    var token = await _meAPI.token;
    write(json.encode({"action": "register", "token": token.token}));
  }

  @override
  Future<void> handleData(dynamic data) async {
    try {
      var payload = json.decode(data as String) as Map<String, dynamic>;
      var pushActionDM = PushActionDM.fromData(payload);
      if (pushActionDM != null) {
        callback(PushAction.fromDM(pushActionDM));
      }
    } on Exception catch (e) {
      print('Failed parse message from upstream, error $e');
      print(data);
    }
  }

  @override
  String pingMessage() {
    return json.encode({"action": "ping"});
  }

  @override
  void onStateChange(ConnectionState state) {
    print('Websockets $state');
  }
}
