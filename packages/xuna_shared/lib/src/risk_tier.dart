/// Shared risk tier definitions (`R0`..`R4`) across XTP v1 and mobile action/host
/// policies (`ADR-0012`, `UDC-0` §3.2, `UDC-4` §5.2).
library;

/// Canonical risk tier `R0`..`R4` (`ADR-0012`).
///
/// - `r0`: read-only or no-side-effect observation.
/// - `r1`: low-risk reversible action (e.g. media key, window focus, timer).
/// - `r2`: state-changing action requiring owner approval or active grant.
/// - `r3`: high-risk / destructive action requiring per-invocation approval.
/// - `r4`: forbidden in XTP v1 MVP.
enum SharedRiskTier implements Comparable<SharedRiskTier> {
  r0('R0', 'r0', 0),
  r1('R1', 'r1', 1),
  r2('R2', 'r2', 2),
  r3('R3', 'r3', 3),
  r4('R4', 'r4', 4);

  const SharedRiskTier(this.xtpWire, this.lowerWire, this.level);

  /// Uppercase XTP v1 wire representation (`'R0'`..`'R4'`).
  final String xtpWire;

  /// Lowercase mobile/JSON wire representation (`'r0'`..`'r4'`).
  final String lowerWire;

  /// Numeric rank (`0`..`4`).
  final int level;

  /// Alias for [xtpWire] to match XTP `RiskTier.wire`.
  String get wire => xtpWire;

  /// Alias for [level] to match mobile `HostRiskTier.rank`.
  int get rank => level;

  /// Whether this tier is valid as an interactive pending action approval tier
  /// (`R1`..`R3` in mobile `ActionRiskTier`).
  bool get isActionTier =>
      this == SharedRiskTier.r1 ||
      this == SharedRiskTier.r2 ||
      this == SharedRiskTier.r3;

  /// Whether this tier is valid as a host capability grant tier (`R0`..`R3` in
  /// mobile `HostRiskTier`).
  bool get isHostGrantTier => level <= SharedRiskTier.r3.level;

  /// Whether this tier is forbidden in XTP v1 MVP (`R4`).
  bool get isForbiddenInMvp => this == SharedRiskTier.r4;

  bool operator <(SharedRiskTier other) => level < other.level;
  bool operator <=(SharedRiskTier other) => level <= other.level;
  bool operator >(SharedRiskTier other) => level > other.level;
  bool operator >=(SharedRiskTier other) => level >= other.level;

  @override
  int compareTo(SharedRiskTier other) => level.compareTo(other.level);

  /// Parses an XTP wire string (`'R0'`..`'R4'`) strictly.
  static SharedRiskTier fromXtpWire(String value) => switch (value) {
        'R0' => SharedRiskTier.r0,
        'R1' => SharedRiskTier.r1,
        'R2' => SharedRiskTier.r2,
        'R3' => SharedRiskTier.r3,
        'R4' => SharedRiskTier.r4,
        _ => throw FormatException('Unknown XTP risk tier: $value'),
      };

  /// Parses either uppercase (`'R0'`..`'R4'`) or lowercase (`'r0'`..`'r4'`)
  /// wire strings, throwing [FormatException] on unknown values.
  static SharedRiskTier fromWire(String value) => switch (value.trim()) {
        'R0' || 'r0' => SharedRiskTier.r0,
        'R1' || 'r1' => SharedRiskTier.r1,
        'R2' || 'r2' => SharedRiskTier.r2,
        'R3' || 'r3' => SharedRiskTier.r3,
        'R4' || 'r4' => SharedRiskTier.r4,
        _ => throw FormatException('Unknown risk tier: $value'),
      };

  /// Parses a wire string or returns `null` if unrecognized.
  static SharedRiskTier? tryParse(String? value) {
    if (value == null) return null;
    return switch (value.trim()) {
      'R0' || 'r0' => SharedRiskTier.r0,
      'R1' || 'r1' => SharedRiskTier.r1,
      'R2' || 'r2' => SharedRiskTier.r2,
      'R3' || 'r3' => SharedRiskTier.r3,
      'R4' || 'r4' => SharedRiskTier.r4,
      _ => null,
    };
  }

  /// Parses a mobile host grant risk tier (`'R0'`..`'R3'` or `'r0'`..`'r3'`),
  /// defaulting to [fallback] if unrecognized or out of range (`R4`).
  static SharedRiskTier parseHostGrantTier(
    String? value, {
    SharedRiskTier fallback = SharedRiskTier.r1,
  }) {
    final parsed = tryParse(value);
    if (parsed == null || !parsed.isHostGrantTier) {
      return fallback;
    }
    return parsed;
  }

  /// Parses a mobile pending-action risk tier (`'R1'`..`'R3'` or `'r1'`..`'r3'`),
  /// clamping `R0` to `R1` and defaulting unknown/`R4` values to [fallback].
  static SharedRiskTier parseActionTier(
    String? value, {
    SharedRiskTier fallback = SharedRiskTier.r2,
  }) {
    final parsed = tryParse(value);
    if (parsed == null || parsed == SharedRiskTier.r4) {
      return fallback;
    }
    if (parsed == SharedRiskTier.r0) {
      return SharedRiskTier.r1;
    }
    return parsed;
  }
}
