String asDollars(int amount) {
  double inDollars = amount / 100;
  if (inDollars == inDollars.roundToDouble()) {
    return '\$${inDollars.toStringAsFixed(0)}';
  }
  return '\$${inDollars.toStringAsFixed(2)}';
}
