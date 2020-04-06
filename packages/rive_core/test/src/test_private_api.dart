import 'dart:io';

class TestPrivateApi {
  HttpServer _server;
  Future<bool> listen(int port) async {
    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
    );
    return _server != null;
  }

  Future<void> startServing() async {
    await for (HttpRequest request in _server) {
      print("GOT REQUEST ${request.uri}");
      request.response.write('Hello, world!');
      await request.response.close();
    }
  }
}
