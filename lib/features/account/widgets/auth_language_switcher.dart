import 'package:flutter/material.dart';
import 'package:iptv/shared/widgets/language_picker.dart';

/// Compact EN / العربية control for the sign-in journey.
///
/// Thin wrapper around [LanguagePicker] so auth screens keep a stable import.
class AuthLanguageSwitcher extends StatelessWidget {
  const AuthLanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return const LanguagePicker(style: LanguagePickerStyle.compact);
  }
}
