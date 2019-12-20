import 'dart:async';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

class ChangeEntry {
  final Object from;
  Object to;

  ChangeEntry(this.from, this.to);
}

// TODO:
// - implement undo/redo
// - implement journal tracker (index based)
// - catches up to perform network sync of changes
// journal[change_index][object_id][property] = {from, to}

abstract class CoreContext {
  final Map<int, Core> objects = <int, Core>{};
  final List<Map<int, Map<int, ChangeEntry>>> journal =
      <Map<int, Map<int, ChangeEntry>>>[];

  Map<int, Map<int, ChangeEntry>> _currentChanges;
  int _journalIndex = 0;
  bool _isRecording = true;
  final Map<int, Core> _objects = {};

  void changeProperty<T>(Core object, int propertyKey, T from, T to) {
    if (!_isRecording) {
      return;
    }
    if (to is String) {
      _channel.sink.add(to);
      var buffer = Uint8List(4);
      buffer[0] = 0;
      buffer[1] = 1;
      buffer[2] = 2;
      buffer[3] = 3;
      _channel.sink.add(buffer);
    }
    _currentChanges ??= <int, Map<int, ChangeEntry>>{};
    var changes = _currentChanges[object.id];
    if (changes == null) {
      _currentChanges[object.id] = changes = <int, ChangeEntry>{};
    }
    var change = changes[propertyKey];
    if (change == null) {
      changes[propertyKey] = change = ChangeEntry(from, to);
    } else {
      change.to = to;
    }
  }

  bool undo() {
    int index = _journalIndex - 1;
    if (journal.isEmpty || index >= journal.length || index < 0) {
      return false;
    }

    _isRecording = false;
    _journalIndex = index;
    var changes = journal[index];
    changes.forEach((objectId, changes) {
      var object = _objects[objectId];
      if (object != null) {
        changes.forEach((propertyKey, change) {
          setObjectProperty(object, propertyKey, change.from);
        });
      }
    });
    _isRecording = true;
    return true;
  }

  void setObjectProperty(Core object, int propertyKey, Object value);

  bool redo() {
    int index = _journalIndex;
    if (journal.isEmpty || index >= journal.length || index < 0) {
      return false;
    }

    _isRecording = false;
    _journalIndex = index + 1;
    var changes = journal[index];
    changes.forEach((objectId, changes) {
      var object = _objects[objectId];
      if (object != null) {
        changes.forEach((propertyKey, change) {
          setObjectProperty(object, propertyKey, change.to);
        });
      }
    });
    _isRecording = true;
    return true;
  }

  void captureJournalEntry() {
    if (_currentChanges == null) {
      return;
    }
    journal.removeRange(_journalIndex, journal.length);
    journal.add(_currentChanges);
    _journalIndex = journal.length;
    _currentChanges = null;
  }

  T add<T extends Core>(T object) {
    object.id ??= localId--;
    object.context = this;
    _objects[object.id] = object;
    return object;
  }

  void remove<T extends Core>(T object) {
    _objects.remove(object.id);
  }

  bool isHolding(Core object) {
    return _objects.containsValue(object);
  }

  bool _isConnected = false;
  WebSocketChannel _channel;
  // WebSocket _socket;

  int _reconnectAttempt = 0;
  Timer _reconnectTimer;
  Future<void> _reconnect() async {
    _reconnectTimer?.cancel();
    if (_reconnectAttempt < 1) {
      _reconnectAttempt = 1;
    }
    _reconnectAttempt *= 2;
    print("WILL WAIT ${_reconnectAttempt * 500}");
    _reconnectTimer =
        Timer(Duration(milliseconds: _reconnectAttempt * 500), connect);
  }

  Future<bool> connect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    print("CALLING CONNECT");
    const url = 'ws://localhost:8000/';
    // await _channel?.sink?.close();
    _channel = WebSocketChannel.connect(Uri.parse(url));
    var completer = Completer<bool>();

    _isConnected = false;
    // first message to force a message back...
    print("GO!");

    _channel.stream.listen((dynamic data) {
      if (!_isConnected) {
        _reconnectAttempt = 0;
        _isConnected = true;
        completer.complete(true);
        completer = null;
      }
      print("socket message: $data");

      // _channel.stream.listen(_dataHandler);
    }, onError: (dynamic error) {
      _isConnected = false;
      print("ERROR $error");
      //_reconnect();
    }, onDone: () {
      _isConnected = false;
      print("DONE!");
      completer?.complete(false);
      _reconnect();
    });
    return completer.future;

    // try {
    //   _socket = await WebSocket.connect(url.toString())
    //       .timeout(const Duration(seconds: 10));
    // } on WebSocketException catch (error) {
    //   await _socket?.close();
    //   print(error);
    //   return false;
    // } on TimeoutException catch (error) {
    //   await _socket?.close();
    //   print(error);
    //   return false;
    // }
    // _socket.listen(_dataHandler);
    // return true;
    // _channel = IOWebSocketChannel(socket);
    // bool connected = false;
    // // _channel = IOWebSocketChannel.connect('wss://echo.websocket.org');
    // StreamSubscription subscription;
    // var completer = Completer<bool>();
    // subscription = _channel.stream.listen((dynamic data) {
    //   print('huh');
    //   if (connected) {
    //     return;
    //   }
    //   print("CONNECT DATA $data");
    //   subscription.cancel();
    //   connected = true;
    //   completer.complete(true);
    //   _channel.stream.listen(_dataHandler);
    // });
    // return completer.future;
  }

  // void _dataHandler(dynamic message) {
  //   print("socket message: $message");
  // }

  void onConnected() {}
}

int localId = 0;

class Core {
  int id;
  CoreContext context;
}
