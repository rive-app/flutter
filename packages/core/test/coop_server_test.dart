import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:core/coop/coop_server.dart';
import 'package:core/coop/protocol_version.dart' show protocolVersion;

void _configureLogging() {
  Logger.root.level = Level.SHOUT; // defaults to Level.INFO
  // Printing to console for the momemt
  Logger.root.onRecord.listen((r) {
    print('${r.level.name}: ${r.time}: ${r.message}');
  });
}

void main() {
  final segments = ['v$protocolVersion', '3', '4', '5'];

  setUp(_configureLogging);
  group('WebSocketData', () {
    test('WebSocketData segments are parsed correctly', () {
      final testSegments = List<String>.from(segments);
      final data = WebSocketData.fromSegments(testSegments);
      expect(data.version, protocolVersion);
      expect(data.fileId, 3);
      expect(data.userOwnerId, 4);
      expect(data.clientId, 5);
    });
    test('WebSocketData throws format exception if "v" ommitted from version',
        () {
      final testSegments = List<String>.from(segments);
      testSegments[0] = '5';
      expect(() => WebSocketData.fromSegments(testSegments),
          throwsA(const TypeMatcher<FormatException>()));
    });
    test('WebSocketData throws format exception for non int ids', () {
      final testSegments = List<String>.from(segments);
      testSegments[1] = 'bob';
      expect(() => WebSocketData.fromSegments(testSegments),
          throwsFormatException);
    });
    test('WebSocketData does not throw an exception for an invalid client id',
        () {
      final testSegments = List<String>.from(segments);
      testSegments[3] = 'bob';
      final data = WebSocketData.fromSegments(testSegments);
      expect(data.clientId, 0);
    });
  });
}
