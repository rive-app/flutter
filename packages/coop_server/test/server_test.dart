import 'dart:async';
import 'dart:io';
import 'package:coop_server_library/server.dart';
import 'package:test/test.dart';

void main() {
  const tempDir = '/tmp/server_test';
  RiveCoopServer coopServer;

  setUp(() {
    Directory(tempDir).createSync(recursive: true);
    coopServer = RiveCoopServer();
  });

  tearDown(() async {
    Directory(tempDir).deleteSync(recursive: true);
    await coopServer?.close();
  });

  test('server starts', () async {
    expect(
        await coopServer.listen(
          port: 8234,
          options: {
            'data-dir': tempDir,
          },
        ),
        true);
  });

  test(
    'server responds to requests',
    () async {
      // Fire up the server
      final result = await coopServer.listen(
        port: 8234,
        options: {
          'data-dir': tempDir,
        },
      );
      expect(result, true);

      // Have a completer to wait for network traffic to finish
      Completer<void> completer = Completer();

      final client = HttpClient();
      final req = await client.get('localhost', 8234, '/');
      final res = await req.close();
      res.listen(
        (data) => expect(String.fromCharCodes(data), 'Healthy'),
        onDone: () => completer.complete(),
      );
      // // create the client
      // await Socket.connect('localhost', 8234).then((socket) {
      //   socket.listen(
      //     (data) {
      //       parseHeader(data);
      //       final str = String.fromCharCodes(data);
      //       expect(str.contains('Healthy'), true);
      //     },
      //     onError: (Object err, StackTrace stack) {
      //       assert(false, 'should not get a networking error: $err');
      //     },
      //     onDone: () {
      //       completer.complete();
      //     },
      //     cancelOnError: true,
      //   );
      //   // write the http craft and ask for '/'
      //   const connectStr = 'GET /index.html HTTP/1.1\r\n'
      //       'User-Agent: nc/0.0.1\r\n'
      //       'Host: 127.0.0.1\r\n'
      //       'Accept: */*\r\n\r\n';
      //   socket.write(connectStr);
      // });

      await completer.future;
    },
    timeout: const Timeout(Duration(seconds: 2)),
  );

  test('server rejects invalid file requests', () async {
    // Fire up the server
    final result = await coopServer.listen(
      port: 8234,
      options: {
        'data-dir': tempDir,
      },
    );
    expect(result, true);

    const segments = 'v2/1/2/3';
    final client = HttpClient();
    final req = await client.get('localhost', 8234, segments);
    final res = await req.close();
    expect(res.statusCode, 400);
  });
}
