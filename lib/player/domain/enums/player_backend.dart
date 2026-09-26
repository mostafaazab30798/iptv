enum PlayerBackend {
  mediaKit('MediaKit', 'media_kit'),
  media3('Media3 (ExoPlayer)', 'media3'),
  vlc('VLC', 'vlc');

  const PlayerBackend(this.label, this.storageValue);

  final String label;
  final String storageValue;

  static PlayerBackend fromStorage(String? value) =>
      PlayerBackend.values.firstWhere(
        (backend) => backend.storageValue == value,
        orElse: () => PlayerBackend.mediaKit,
      );
}
