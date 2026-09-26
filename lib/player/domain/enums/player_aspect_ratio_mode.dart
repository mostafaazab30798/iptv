import 'package:flutter/painting.dart';

/// Display policies shared by every player backend.
///
/// The stored [index] values intentionally match the original player UI so
/// existing preferences and remote-control shortcuts remain compatible.
enum PlayerAspectRatioMode {
  bestFit('Best Fit'),
  fit('Fit'),
  fill('Fill'),
  ratio16x9('16:9'),
  ratio4x3('4:3');

  const PlayerAspectRatioMode(this.label);

  final String label;

  static PlayerAspectRatioMode fromIndex(int index) =>
      PlayerAspectRatioMode.values.firstWhere(
        (mode) => mode.index == index,
        orElse: () => PlayerAspectRatioMode.bestFit,
      );

  PlayerAspectRatioMode get next =>
      PlayerAspectRatioMode.values[(index + 1) % values.length];

  /// A fixed output frame for legacy broadcasts that need explicit shaping.
  double? get forcedAspectRatio => switch (this) {
    PlayerAspectRatioMode.ratio16x9 => 16 / 9,
    PlayerAspectRatioMode.ratio4x3 => 4 / 3,
    _ => null,
  };

  /// How a backend surface should paint inside its output frame.
  BoxFit get surfaceFit => switch (this) {
    PlayerAspectRatioMode.fill => BoxFit.cover,
    // Fixed-ratio modes intentionally reshape the decoded image. Using
    // contain here would only add a second set of black bars.
    PlayerAspectRatioMode.ratio16x9 ||
    PlayerAspectRatioMode.ratio4x3 => BoxFit.fill,
    _ => BoxFit.contain,
  };
}
