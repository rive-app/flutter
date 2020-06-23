import 'package:test/test.dart';

import 'package:utilities/utilities.dart';

void main() {
  test('Encode ids', () {
    final ids = [12, 24, 36];
    final hashedIds = encodeIds(ids);
    expect(hashedIds, '54CXFZ');
  });

  test('Decode ids', () {
    const hash = '54CXFZ';
    final ids = decodeIds(hash);
    expect(ids, [12, 24, 36]);
  });
}
