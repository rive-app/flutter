import 'package:hashids2/hashids2.dart';

export 'date_time.dart';
export 'deserialize.dart';
export 'iterable.dart';
export 'string.dart';
export 'stripe.dart';
export 'tops.dart';

/// Szudzik's function for hashing two ints together
int szudzik(int a, int b) {
  assert(a != null && b != null);
  // a and b must be >= 0

  int x = a.abs();
  int y = b.abs();
  return x >= y ? x * x + x + y : x + y * y;
}

/// Returns true if the difference between a and b is above a certain threshold.
bool threshold(double a, double b, [double threshold = 0.0001]) =>
    (a - b).abs() > threshold;

/// Salt used when hashing the ids together
const _hashSalt = 'vjQ7gzOrXi';

/// Encode integer ids in a hash
String encodeIds(Iterable<int> ids) => HashIds(salt: _hashSalt).encode(ids);

/// Decode two integer ids from a hash
List<int> decodeIds(String hash) => HashIds(salt: _hashSalt).decode(hash);

/// Decide on light or dark font color based on background color contrast
/// If true, use a dark color, if false, use a light color
bool useDarkContrast(int red, int green, int blue) =>
    red * 0.299 + green * 0.587 + blue * 0.114 > 186;
