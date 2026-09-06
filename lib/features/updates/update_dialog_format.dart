import 'package:flutter/material.dart';
import 'package:iptv/core/releases/release_manifest.dart';

String? releaseNotesForLocale(ReleaseManifest manifest, Locale locale) {
  if (locale.languageCode == 'ar') {
    return manifest.releaseNotesAr ?? manifest.releaseNotesEn;
  }
  return manifest.releaseNotesEn ?? manifest.releaseNotesAr;
}

String formatUpdateFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
