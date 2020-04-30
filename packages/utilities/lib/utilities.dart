export 'date_time.dart';
export 'deserialize.dart';
export 'iterable.dart';
export 'string.dart';
export 'stripe.dart';

/// Szudzik's function for hashing two ints together
int _szudzik(int a, int b) {
  // a and b must be >= 0
  int x = a.abs();
  int y = b.abs();
  return x >= y ? x * x + x + y : x + y * y;
}
