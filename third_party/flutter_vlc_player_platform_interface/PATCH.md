# Local Pigeon channel compatibility patch

`flutter_vlc_player` 7.4.4 registers its Android and iOS handlers with the
current Pigeon list codec under
`dev.flutter.pigeon.flutter_vlc_player_platform_interface.VlcPlayerApi.*`.
The pub.dev archive for its Dart interface 2.0.5 contains stale generated code:
it uses the old map codec and omits the package namespace. This directory uses
the generated interface committed at the official upstream `7.4.4` tag
(`988a7e67140786fb5510c96e4cb415dbfd837944`) so Dart and both native plugins
share the same channel names and message format.
