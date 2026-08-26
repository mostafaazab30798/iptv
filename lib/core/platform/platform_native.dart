import 'dart:io' show Platform;

/// Native (non-web) platform stub.
bool platformIsWindows() => Platform.isWindows;
bool platformIsAndroid() => Platform.isAndroid;
