/// Platform specific settings
/// This one's for native platforms

class PlatformSpecific {
  factory PlatformSpecific() => _instance;
  const PlatformSpecific._();
  static const PlatformSpecific _instance = PlatformSpecific._();

  // Tab offset
  double get leftOffset => 69;
}
