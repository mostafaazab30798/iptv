/// Allowlisted analytics event names (master plan §13.2).
enum AnalyticsEventName {
  appFirstOpen('app_first_open'),
  appUpdated('app_updated'),
  sessionStarted('session_started'),
  sessionHeartbeat('session_heartbeat'),
  sessionEnded('session_ended'),
  accountCreated('account_created'),
  accountSignedIn('account_signed_in'),
  deviceRegistered('device_registered'),
  trialStarted('trial_started'),
  trialExpiring('trial_expiring'),
  trialExpired('trial_expired'),
  subscriptionPageOpened('subscription_page_opened'),
  subscriptionActivated('subscription_activated'),
  subscriptionRenewed('subscription_renewed'),
  paymentFailed('payment_failed'),
  subscriptionCanceled('subscription_canceled'),
  entitlementRefreshed('entitlement_refreshed'),
  entitlementDenied('entitlement_denied'),
  iptvConnectionSucceeded('iptv_connection_succeeded'),
  playbackStarted('playback_started'),
  playbackFailed('playback_failed'),
  downloadAuthorized('download_authorized'),
  releaseDownloadRequested('release_download_requested'),
  updateAvailable('update_available'),
  updateDownloaded('update_downloaded');

  const AnalyticsEventName(this.value);
  final String value;
}

class AnalyticsEvent {
  const AnalyticsEvent({
    required this.eventId,
    required this.name,
    required this.occurredAt,
    this.schemaVersion = 1,
    this.platform,
    this.appVersion,
    this.installationIdHash,
    this.properties = const {},
  });

  final String eventId;
  final AnalyticsEventName name;
  final DateTime occurredAt;
  final int schemaVersion;
  final String? platform;
  final String? appVersion;
  final String? installationIdHash;
  final Map<String, Object?> properties;

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'eventName': name.value,
        'schemaVersion': schemaVersion,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        if (platform != null) 'platform': platform,
        if (appVersion != null) 'appVersion': appVersion,
        if (installationIdHash != null) 'installationIdHash': installationIdHash,
        if (properties.isNotEmpty) 'properties': properties,
      };
}
