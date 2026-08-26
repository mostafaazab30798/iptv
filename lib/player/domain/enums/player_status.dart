/// Canonical lifecycle status of the playback engine.
enum PlayerStatus {
  idle,
  initializing,
  loading,
  buffering,
  playing,
  paused,
  stopped,
  completed,
  error,
  disposed;

  bool get isIdle => this == PlayerStatus.idle;
  bool get isInitializing => this == PlayerStatus.initializing;
  bool get isLoading => this == PlayerStatus.loading;
  bool get isBuffering => this == PlayerStatus.buffering;
  bool get isPlaying => this == PlayerStatus.playing;
  bool get isPaused => this == PlayerStatus.paused;
  bool get isStopped => this == PlayerStatus.stopped;
  bool get isCompleted => this == PlayerStatus.completed;
  bool get isError => this == PlayerStatus.error;
  bool get isDisposed => this == PlayerStatus.disposed;

  bool get isActive =>
      this == PlayerStatus.playing ||
      this == PlayerStatus.paused ||
      this == PlayerStatus.buffering ||
      this == PlayerStatus.loading;
}
