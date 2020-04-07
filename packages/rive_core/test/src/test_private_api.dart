import 'dart:io';

import 'dart:typed_data';

class TestPrivateApi {
  HttpServer _server;
  int _monotonicID = 1;
  Map<String, Uint8List> filesData = {};
  Future<bool> listen(int port) async {
    _server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
    );
    return _server != null;
  }

  Future<void> startServing() async {
    await for (final request in _server) {
      print("SEGS ${request.uri.pathSegments} ${request.method}");
      var segs = request.uri.pathSegments;
      if (segs.length == 3) {
        switch (segs[0]) {
          case 'revise':
            var data = (await request.fold(
                    BytesBuilder(), (BytesBuilder b, d) => b..add(d)))
                .takeBytes();
            String key = '${segs[1]}-${segs[2]}';
            filesData[key] = data;
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
