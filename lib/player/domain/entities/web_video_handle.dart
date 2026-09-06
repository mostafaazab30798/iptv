typedef WebAspectRatioCallback = void Function(int index, [double scale]);

/// Opaque platform handle representing an active HTML5 video element on the web.
class WebVideoHandle {
  const WebVideoHandle({
    required this.viewTypeId,
    this.videoElement,
    this.onAspectRatioChanged,
  });

  /// Unique platform view registration identifier for [HtmlElementView].
  final String viewTypeId;

  /// Optional underlying web video element reference.
  final Object? videoElement;

  /// Callback triggered when the UI updates the display aspect ratio.
  final WebAspectRatioCallback? onAspectRatioChanged;

  @override
  String toString() => 'WebVideoHandle(viewTypeId: $viewTypeId)';
}
