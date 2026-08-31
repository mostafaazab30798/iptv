import 'package:flutter/material.dart';

/// Stable navigator keys shared by [GoRouter] and system-back handling.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shellNav');
