import 'dart:io';

import 'dart:typed_data';

class TestPrivateApi {
  HttpServer _server;
  int _monotonicID = 1;
  Duration responseDelay;
  Map<String, Uint8List> filesData = {};

  Future<bool> close() async {
    await _server.close(force: true);
    return true;
  }

  Future<bool> listen(int port) async {
    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
    );
    return _server != null;
  }

  Future<void> startServing() async {
    await for (final request in _server) {
      var segs = request.uri.pathSegments;
      if (segs.length == 2) {
        switch (segs[0]) {
          case 'revise':
            var data = (await request.fold(
                    BytesBuilder(), (BytesBuilder b, d) => b..add(d)))
                .takeBytes();
            String key = segs[1];
            filesData[key] = data;
            if (responseDelay != null) {
              await Future<void>.delayed(responseDelay);
            }
            request.response.write(
                '''{"key":"key-$_monotonicID","revision_id":$_monotonicID, "size":${data.length}}''');
            _monotonicID++;
            break;
        }
      }

      await request.response.close();
    }
  }
}
