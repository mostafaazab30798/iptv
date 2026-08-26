class ServerPreset {
  final String id;
  final String name;
  final String url;
  final String? description;

  const ServerPreset({
    required this.id,
    required this.name,
    required this.url,
    this.description,
  });
}

abstract final class ServerPresets {
  static const List<ServerPreset> presets = [
    ServerPreset(
      id: 'maven_tv',
      name: 'MAVEN TV',
      url: 'http://fndueo.2m2h.im:80',
      description: 'Primary Fast Server',
    ),
    ServerPreset(
      id: 'xtream_backup',
      name: 'Server 2 (Backup)',
      url: 'http://fndueo.2m2h.im',
      description: 'Alternative Gateway',
    ),
  ];

  static const String customServerId = 'custom';
  static const ServerPreset customPreset = ServerPreset(
    id: customServerId,
    name: 'Custom Server',
    url: '',
    description: 'Enter your own server URL manually',
  );
}
