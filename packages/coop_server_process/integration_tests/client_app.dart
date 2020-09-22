import 'dart:io';

/// Mimics a Rive client app talking to a coop server

Future<void> main() async {
  print('Client app running');

  final socket = await WebSocket.connect('ws://localhost:8000');
  // 'wss://echo.websocket.org');

  socket.listen((dynamic data) {
    print('DATA RECEIVEd: $data');
    //socket.add(data);
  }, onDone: () {
    print('Connection terminated');
    socket.close();
  });

  print('Sending data');
  socket.add('BOB');
}

/*
 * Client actions
 */

void createArtboard() {}

void createShape() {}
