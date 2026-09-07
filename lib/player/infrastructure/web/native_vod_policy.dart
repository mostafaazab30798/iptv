/// Returns the target URL when [url] points at the app's web proxy.
String unwrapWebProxyTarget(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.path.contains('/proxy')) {
    return url;
  }
  return uri.queryParameters['url'] ?? url;
}

/// Whether an iOS native video element needs a compatibility remux.
///
/// MP4, MOV, M4V, and HLS should be assigned directly to `<video>`. In
/// particular, probing every movie with JavaScript breaks otherwise playable
/// cross-origin MP4 streams because `fetch` requires CORS while `<video>` does
/// not. Matroska and AVI are the known containers that AVPlayer cannot demux.
bool requiresIosVodRemux(String url) {
  final target = unwrapWebProxyTarget(url);
  final path = Uri.tryParse(target)?.path.toLowerCase() ?? target.toLowerCase();
  return path.endsWith('.mkv') || path.endsWith('.avi');
}
