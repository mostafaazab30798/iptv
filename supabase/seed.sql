-- Non-secret HOPE TV plan stubs (display placeholders; not billable).

insert into public.plans (code, name, interval, enabled, sort_order)
values
  ('monthly', 'HOPE TV Monthly', 'month', true, 1),
  ('yearly', 'HOPE TV Yearly', 'year', true, 2)
on conflict (code) do nothing;

insert into public.plan_prices (plan_id, currency, amount_minor, display_amount, provider_price_id, enabled)
select p.id, 'USD', 999, 'PLACEHOLDER_MONTHLY_PRICE', null, true
from public.plans p
where p.code = 'monthly'
on conflict (plan_id, currency) do nothing;

insert into public.plan_prices (plan_id, currency, amount_minor, display_amount, provider_price_id, enabled)
select p.id, 'USD', 9999, 'PLACEHOLDER_YEARLY_PRICE', null, true
from public.plans p
where p.code = 'yearly'
on conflict (plan_id, currency) do nothing;

insert into public.remote_config_versions (version, payload, published_by)
values (
  1,
  jsonb_build_object(
    'productName', 'HOPE TV',
    'trialDurationDays', 7,
    'deviceLimit', 3,
    'gracePeriodHours', 72,
    'offlineLeaseHours', 24,
    'portalUrl', 'https://hope-tv.site',
    'supportEmail', 'support@hope-tv.site',
    'supportUrl', 'mailto:support@hope-tv.site',
    'billingConfigured', false,
    'distributionMode', 'github_releases',
    'analyticsEnabled', true,
    'minimumSupportedVersion', '0.1.0',
    'features', jsonb_build_object(
      'liveTv', true,
      'movies', true,
      'series', true,
      'favorites', true,
      'history', true
    )
  ),
  'seed'
)
on conflict (version) do nothing;

-- Unpublished release metadata stub. Production CI replaces object_key with the
-- corresponding public GitHub Releases asset URL before publishing.
insert into public.release_versions (
  platform,
  architecture,
  channel,
  version,
  build_number,
  object_key,
  file_size_bytes,
  sha256,
  minimum_supported_prior_version,
  mandatory_update,
  release_notes_en,
  release_notes_ar
)
values (
  'android',
  'universal',
  'stable',
  '0.1.0',
  1,
  'https://github.com/mostafaazab30798/iptv/releases/download/v0.1.0/HOPE_IPTV.apk',
  null,
  'PLACEHOLDER_SHA256_DIGEST',
  '0.0.0',
  false,
  'Initial HOPE TV Android release metadata for GitHub Releases.',
  null
)
on conflict (platform, channel, version, architecture) do nothing;
