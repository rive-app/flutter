import 'dart:io';
import 'package:coop_server_library/server.dart';
import 'package:test/test.dart';

void main() {
  const String tempDir = '/tmp/server_test';
  setUp(() async {
    var dir = Directory(tempDir);
    dir.createSync(recursive:true);
  });

  tearDown(() async {
    var dir = Directory(tempDir);
    dir.deleteSync(recursive:true);
  });

  test('server can start', () async {
    
    var server = RiveCoopServer();
    var result = await server.listen(
      port: 8234,
      options: {
        'data-dir': tempDir,
      },
    );

    expect(result, true);
  });
}
