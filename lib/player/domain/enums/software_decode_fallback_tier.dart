/// Two-tier software decode escalation strategy for channels that exceed
/// the device's hardware decoder capability.
///
/// - [none]: Hardware decoding is active. No software decode fallback applied.
/// - [loopFilterSkip]: HW decode failed; applied immediately when SW decode is detected.
///   Skips loop filter on non-key frames — almost no visual impact, frees ~15-20% CPU.
/// - [frameSkip]: Escalated after sustained high drop rate under loopFilterSkip.
///   Skips non-reference frames entirely — recovers frame budget but introduces motion ghosting.
///   Auto-de-escalates back to [loopFilterSkip] when drop rate recovers.
enum SoftwareDecodeFallbackTier {
  none,
  loopFilterSkip,
  frameSkip;

  String get displayName => switch (this) {
        SoftwareDecodeFallbackTier.none => 'None (HW Active)',
        SoftwareDecodeFallbackTier.loopFilterSkip => 'Loop Filter Skip (Tier 1)',
        SoftwareDecodeFallbackTier.frameSkip => 'Frame Skip (Tier 2)',
      };

  bool get isSoftwareFallback => this != SoftwareDecodeFallbackTier.none;
}
