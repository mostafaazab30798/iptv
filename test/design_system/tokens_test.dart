import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/core/design_system/tokens.dart';

void main() {
  test('design token facade preserves core product values', () {
    expect(DesignTokens.primary, AppColors.accent);
    expect(DesignTokens.neutral0, AppColors.bg0);
    expect(DesignTokens.neutral95, AppColors.textPrimary);
    expect(DesignTokens.space16, 16);
    expect(DesignTokens.radius8, 8);
    expect(DesignTokens.motionCurve, Curves.easeOutCubic);
    expect(DesignTokens.surfaceShadow, hasLength(1));
  });
}
