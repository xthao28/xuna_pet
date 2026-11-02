/// Shared host operating system platform definitions across XTP v1 and mobile
/// host management.
library;

/// Supported operating system platforms for enrolled XUNA hosts.
enum SharedHostPlatform {
  windows('windows'),
  macos('macos'),
  linux('linux'),
  android('android'),
  ios('ios');

  const SharedHostPlatform(this.wire);

  /// Canonical lowercase wire representation (`'windows'`, `'macos'`, `'linux'`,
  /// `'android'`, `'ios'`).
  final String wire;

  /// Whether this platform represents a desktop operating system.
  bool get isDesktop =>
      this == SharedHostPlatform.windows ||
      this == SharedHostPlatform.macos ||
      this == SharedHostPlatform.linux;

  /// Whether this platform represents a mobile operating system.
  bool get isMobile =>
      this == SharedHostPlatform.android || this == SharedHostPlatform.ios;

  /// Parses a canonical wire string strictly, throwing [FormatException] on
  /// unknown values.
  static SharedHostPlatform fromWire(String value) => switch (value) {
        'windows' => SharedHostPlatform.windows,
        'macos' => SharedHostPlatform.macos,
        'linux' => SharedHostPlatform.linux,
        'android' => SharedHostPlatform.android,
        'ios' => SharedHostPlatform.ios,
        _ => throw FormatException('Unknown SharedHostPlatform: $value'),
      };

  /// Parses a wire string (case-insensitive) or returns `null` if unrecognized.
  static SharedHostPlatform? tryParse(String? value) {
    if (value == null) return null;
    return switch (value.trim().toLowerCase()) {
      'windows' => SharedHostPlatform.windows,
      'macos' => SharedHostPlatform.macos,
      'linux' => SharedHostPlatform.linux,
      'android' => SharedHostPlatform.android,
      'ios' => SharedHostPlatform.ios,
      _ => null,
    };
  }
}
