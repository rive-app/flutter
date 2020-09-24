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

  // would be nice to turn the comswebsocket
  CommsWebsocketClient _client;
  NotificationManager _notificationManager;

  WebsocketCommsManager._() {
    _notificationManager = NotificationManager();
    _client = CommsWebsocketClient();
    _attach();
  }

  WebsocketCommsManager.tester(
    NotificationManager notificationsManager,
    CommsWebsocketClient client,
  )   : _notificationManager = notificationsManager,
        _client = client {
    _attach();
  }

  /// Initiatize the state
  void _attach() {
    // make sure our comms client is handling the right action (here to make
    // testing easier)
    _client.callback = handleAction;

    /// When the logged in user is changed, fetch notifications for the new user
    subscribe<model.Me>((_) => _connect());
  }

  Future<void> _connect() async {
    await _client?.disconnect();
    final me = Plumber().peek<model.Me>();
    if (me == null || me.isEmpty) {
      return;
    }
    await _client.connect();
  }

  void handleAction(PushAction action) {
    if (action is model.NewNotification) {
      _notificationManager.update();
    } else if (action is model.PingNotification) {
      print('We were pinged');
    } else if (action is model.FolderNotification) {
      // reload if we're currently here
      var currentDirectory = Plumber().peek<CurrentDirectory>();
      if (currentDirectory != null &&
          currentDirectory.owner.ownerId == action.folderOwnerId &&
          currentDirectory.folder.id == action.folderId) {
        Plumber().message(currentDirectory);
      }
    } else if (action is model.TaskCompleted) {
      Plumber().message(action);
    }
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    _client?.dispose();
  }
}

class CommsWebsocketClient extends ReconnectingWebsocketClient {
  MeApi _meAPI;
  ConfigApi _configAPI;
  Function(PushAction) callback;
  CommsWebsocketClient() : super() {
    _meAPI = MeApi();
    _configAPI = ConfigApi();
  }
  final _raiseErrors = false;
  bool get raiseErrors => _raiseErrors;

  @override
  Future<void> onConnect() async {
    var token = await _meAPI.token;
    write(json.encode({'action': 'register', 'token': token.token}));
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
      if (raiseErrors) {
        rethrow;
      }
    }
  }

  @override
  String pingMessage() => json.encode({'action': 'ping'});

  @override
  void onStateChange(ConnectionState state) => print('Websockets $state');

  @override
  Future<String> getUrl() async {
    var config = await _configAPI.appConfig();
    return config.websocketUrl;
  }
}
