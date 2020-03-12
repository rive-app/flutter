import 'package:test/test.dart';

import 'package:core/web_socket/web_socket.dart';

void main() {
  test('valid cookie headers are generated', () {
    final token = 'thisisatoken==';
    final header = createCookieHeader(token);
    expect(header.length, 1);
    expect(header.keys.first, 'Cookie');
    expect(header.values.first.startsWith('spectre='), true);
    expect(header.keys.first.contains(' '), false);
    expect(header.values.first.endsWith(token), true);
    expect(header.values.first.contains(' '), false);
  });
}
