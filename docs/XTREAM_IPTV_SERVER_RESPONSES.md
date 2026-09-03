# Xtream IPTV Server Responses

Complete catalog of JSON (and non-JSON) responses an Xtream Codes–compatible panel can return. This app talks to the panel through `player_api.php` with `username` and `password` as query parameters.

Base request shape:

```http
GET {server}/player_api.php?username={user}&password={pass}&action={action}
```

Auth (no `action`) is the same URL without `action`.

**Type quirk:** numeric fields are often strings (`"1"`) and sometimes integers (`1`). Dates are usually Unix seconds as a string. The client must accept both.

**Empty results:** panels return `[]`, `{}`, `null`, `""`, or HTML. This app treats unexpected types as empty lists/maps.

Legend:

- **Used** — fetched by `XtreamRemoteDataSource`
- **Defined** — constant exists in `ApiConstants` but not called yet
- **Available** — standard Xtream endpoint, not wired in this app

---

## 1. Authentication — no `action`

**Used.** `GET player_api.php?username=…&password=…`

### 1.1 Success — active account

```json
{
  "user_info": {
    "username": "demo_user",
    "password": "demo_pass",
    "message": "",
    "auth": 1,
    "status": "Active",
    "exp_date": "1893456000",
    "is_trial": "0",
    "active_cons": "1",
    "created_at": "1609459200",
    "max_connections": "2",
    "allowed_output_formats": ["m3u8", "ts", "rtmp"]
  },
  "server_info": {
    "url": "panel.example.com",
    "port": "8080",
    "https_port": "8443",
    "server_protocol": "http",
    "rtmp_port": "1935",
    "timezone": "Europe/London",
    "timestamp_now": 1735689600,
    "time_now": "2026-01-01 00:00:00"
  }
}
```

| Field | Typical values | Notes |
| --- | --- | --- |
| `user_info.auth` | `1`, `"1"`, `true` | App treats any of these as authorized |
| `user_info.status` | `"Active"`, `"Expired"`, `"Banned"`, `"Disabled"` | Case-insensitive. App also accepts `status == "active"` as authorized |
| `user_info.exp_date` | Unix seconds string, ISO datetime, `"0"`, `"null"` | `"0"` / `"null"` / missing = unlimited. App parses Unix seconds as UTC |
| `user_info.is_trial` | `"0"` / `"1"` | |
| `user_info.active_cons` | string or int | Current connections |
| `user_info.max_connections` | string or int | Device/connection cap |
| `user_info.allowed_output_formats` | `["m3u8","ts","rtmp"]` | Which live/VOD wrappers the panel will serve |
| `user_info.message` | string | Shown on failed auth if present |
| `server_info.port` / `https_port` / `rtmp_port` | string | |
| `server_info.timestamp_now` | int | Panel clock |

This app currently reads only `user_info.auth`, `user_info.status`, `user_info.message`, and `user_info.exp_date`.

### 1.2 Failed credentials

```json
{
  "user_info": {
    "auth": 0
  }
}
```

Some panels also include:

```json
{
  "user_info": {
    "username": "demo_user",
    "password": "wrong",
    "message": "Invalid username or password",
    "auth": 0,
    "status": "Disabled"
  },
  "server_info": {}
}
```

App mapping: missing `user_info` → “Could not verify server response”; `auth` not authorized → `message` or “Invalid username or password”.

### 1.3 Expired / banned / disabled (credentials valid)

```json
{
  "user_info": {
    "auth": 1,
    "status": "Expired",
    "exp_date": "1609459200",
    "message": "Your account has expired"
  },
  "server_info": {}
}
```

`status` may be `"Expired"`, `"Banned"`, or `"Disabled"`. App maps these to: `Account is {status}. Please contact your provider.`

### 1.4 Non-JSON / HTTP failures

| What the panel sends | Typical HTTP | App behavior |
| --- | --- | --- |
| Empty body | 200 | Parsed as `{}` → auth fails (no `user_info`) |
| HTML login / nginx page | 200 / 404 / 502 | JSON decode fails → connection error |
| `[]` | 200 | Unexpected type for a map → parse error |
| Nothing useful | 401 / 403 | “Invalid username or password” |
| Nothing useful | 5xx | “Server error (code). Server may be offline.” |
| Connection timeout | — | “Connection timed out…” |

---

## 2. Categories

Same object for live, VOD, and series. **Used.**

| Action | Param |
| --- | --- |
| `get_live_categories` | — |
| `get_vod_categories` | — |
| `get_series_categories` | — |

```json
[
  {
    "category_id": "1",
    "category_name": "Sports",
    "parent_id": 0
  },
  {
    "category_id": "2",
    "category_name": "Football",
    "parent_id": 1
  }
]
```

| Field | Alternate keys the mapper accepts |
| --- | --- |
| `category_id` | `id` |
| `category_name` | `name` |
| `parent_id` | — (optional; `0` = top-level) |

Empty catalog: `[]` or `{}` (app turns `{}` into `[]`).

---

## 3. Live streams — `get_live_streams`

**Used.** Optional `category_id`.

```json
[
  {
    "num": 1,
    "name": "beIN Sports 1 HD",
    "stream_type": "live",
    "stream_id": 4410,
    "stream_icon": "http://panel.example.com/images/bein1.png",
    "epg_channel_id": "beinsports1.qa",
    "added": "1609459200",
    "is_adult": "0",
    "category_id": "1",
    "custom_sid": "",
    "tv_archive": 1,
    "direct_source": "",
    "tv_archive_duration": 7
  }
]
```

| Field | Meaning |
| --- | --- |
| `num` | Playlist index (not the playback id) |
| `stream_id` | Id used in `/live/{user}/{pass}/{stream_id}.{ext}` |
| `name` | Display title (`title` accepted as fallback) |
| `stream_icon` | Logo URL (`cover`, `icon` fallbacks) |
| `epg_channel_id` | XMLTV / EPG channel key |
| `category_id` | String or int. Some panels send `category_ids`: `["1","2"]` |
| `stream_type` | `"live"` |
| `tv_archive` | `1` / `"1"` = catch-up available |
| `tv_archive_duration` | Catch-up window in days |
| `direct_source` | Direct HTTP(S) URL when the panel does not proxy the stream |
| `custom_sid` | DVB SID; usually empty |
| `is_adult` | `"0"` / `"1"` |
| `added` | Unix seconds when the stream was added |

App mapping (`DataMapper.channelFromJson`) uses: `stream_id`/`id`/`num`, `name`/`title`, `stream_icon`/`cover`/`icon`, `category_id`, `epg_channel_id`, `tv_archive`, `tv_archive_duration`.

---

## 4. VOD streams — `get_vod_streams`

**Used.** Optional `category_id`.

```json
[
  {
    "num": 1,
    "name": "The Matrix",
    "stream_type": "movie",
    "stream_id": 5678,
    "stream_icon": "http://panel.example.com/images/matrix.jpg",
    "rating": "8.7",
    "rating_5based": 4.3,
    "added": "1609459200",
    "is_adult": "0",
    "category_id": "10",
    "container_extension": "mp4",
    "custom_sid": "",
    "direct_source": ""
  }
]
```

| Field | Meaning |
| --- | --- |
| `stream_id` | Id used in `/movie/{user}/{pass}/{stream_id}.{ext}` |
| `container_extension` | File wrapper: `mp4`, `mkv`, `avi`, `ts`, `m3u8` |
| `rating` | 10-based string |
| `rating_5based` | 5-based number; app uses this if `rating` is missing |
| `stream_icon` | Poster (`cover`, `movie_image` fallbacks) |

List items usually do **not** include plot/cast/director. Those come from `get_vod_info`.

---

## 5. VOD details — `get_vod_info`

**Defined** (`ApiConstants.actionGetVodInfo`). Not called by `XtreamRemoteDataSource` yet.

Query: `action=get_vod_info&vod_id={stream_id}`

```json
{
  "info": {
    "kinopoisk_url": "",
    "tmdb_id": 603,
    "name": "The Matrix",
    "o_name": "The Matrix",
    "cover_big": "http://image.tmdb.org/t/p/w1280/matrix.jpg",
    "movie_image": "http://image.tmdb.org/t/p/w500/matrix.jpg",
    "releasedate": "1999-03-31",
    "episode_run_time": "136",
    "youtube_trailer": "vKQi3bBA1y8",
    "director": "Lana Wachowski, Lilly Wachowski",
    "actors": "Keanu Reeves, Laurence Fishburne",
    "cast": "Keanu Reeves, Laurence Fishburne, Carrie-Anne Moss",
    "description": "A computer hacker learns from mysterious rebels…",
    "plot": "A computer hacker learns from mysterious rebels…",
    "age": "R",
    "mpaa_rating": "R",
    "rating_count_kinopoisk": 0,
    "country": "USA",
    "genre": "Action, Sci-Fi",
    "backdrop_path": [
      "http://image.tmdb.org/t/p/w1280/backdrop.jpg"
    ],
    "duration_secs": 8160,
    "duration": "02:16:00",
    "video": {},
    "audio": {},
    "bitrate": 2500,
    "rating": "8.7",
    "status": "Released"
  },
  "movie_data": {
    "stream_id": 5678,
    "name": "The Matrix",
    "added": "1609459200",
    "category_id": "10",
    "container_extension": "mkv",
    "custom_sid": "",
    "direct_source": ""
  }
}
```

`info.video` / `info.audio` may be empty objects, or ffprobe-style maps (`codec_name`, `width`, `height`, `display_aspect_ratio`, `bit_rate`, …).

Missing VOD: `[]`, `{}`, or `{ "info": [], "movie_data": [] }`.

---

## 6. Series list — `get_series`

**Used.** Optional `category_id`.

```json
[
  {
    "num": 1,
    "name": "Breaking Bad",
    "series_id": 99,
    "cover": "http://panel.example.com/images/bb.jpg",
    "plot": "A chemistry teacher turned meth cook…",
    "cast": "Bryan Cranston, Aaron Paul",
    "director": "Vince Gilligan",
    "genre": "Crime, Drama",
    "releaseDate": "2008-01-20",
    "last_modified": "1735689600",
    "rating": "9.5",
    "rating_5based": 4.8,
    "backdrop_path": [
      "http://image.tmdb.org/t/p/w1280/bb-backdrop.jpg"
    ],
    "youtube_trailer": "HhesaQXLuRY",
    "episode_run_time": "47",
    "category_id": "20"
  }
]
```

| Field | Alternate keys the mapper accepts |
| --- | --- |
| `series_id` | `id` |
| `cover` | `stream_icon`, `poster` |
| `releaseDate` | `year` |
| `rating` | `rating_5based` |

Playback does **not** use `series_id` in the stream URL. Episode `id` is the stream id (see §7).

---

## 7. Series details — `get_series_info`

**Used.** Query: `action=get_series_info&series_id={id}`

Panels disagree on shape. The app accepts seasons as a list **or** a map, and episodes as a map **or** a flat list.

### 7.1 Canonical shape

```json
{
  "seasons": [
    {
      "air_date": "2008-01-20",
      "episode_count": 7,
      "id": 3572,
      "name": "Season 1",
      "overview": "",
      "season_number": 1,
      "cover": "http://panel.example.com/images/bb-s1.jpg",
      "cover_big": "http://panel.example.com/images/bb-s1-big.jpg"
    }
  ],
  "info": {
    "name": "Breaking Bad",
    "cover": "http://panel.example.com/images/bb.jpg",
    "plot": "A chemistry teacher turned meth cook…",
    "cast": "Bryan Cranston, Aaron Paul",
    "director": "Vince Gilligan",
    "genre": "Crime, Drama",
    "releaseDate": "2008-01-20",
    "last_modified": "1735689600",
    "rating": "9.5",
    "rating_5based": 4.8,
    "backdrop_path": [],
    "youtube_trailer": "HhesaQXLuRY",
    "episode_run_time": "47",
    "category_id": "20"
  },
  "episodes": {
    "1": [
      {
        "id": "10101",
        "episode_num": 1,
        "title": "Pilot",
        "container_extension": "mkv",
        "info": {
          "tmdb_id": 62085,
          "releasedate": "2008-01-20",
          "plot": "A chemistry teacher…",
          "duration_secs": 3480,
          "duration": "00:58:00",
          "movie_image": "http://panel.example.com/images/bb-s1e1.jpg",
          "bitrate": 0,
          "rating": "9.0",
          "season": 1
        },
        "custom_sid": "",
        "added": "1609459200",
        "season": 1,
        "direct_source": ""
      }
    ]
  }
}
```

Episode `id` is the playback stream id:

```text
{server}/series/{user}/{pass}/{id}.{container_extension}
```

### 7.2 Variant: `seasons` as a map

```json
{
  "seasons": {
    "1": {
      "season_number": 1,
      "name": "First Season",
      "cover": "http://example.com/s1.jpg"
    }
  },
  "episodes": {
    "1": [
      {
        "id": "501",
        "episode_num": 1,
        "name": "The Awakening",
        "container_extension": "mp4"
      }
    ]
  }
}
```

### 7.3 Variant: empty `seasons`, episodes still present

```json
{
  "seasons": [],
  "episodes": {
    "1": [{ "id": "801", "episode_num": 1, "title": "Standalone Ep 1", "container_extension": "mp4" }],
    "2": [{ "id": "802", "episode_num": 1, "title": "Standalone Ep 2", "container_extension": "mp4" }]
  }
}
```

App derives `Season 1`, `Season 2` from episode keys.

### 7.4 Variant: `episodes` as a flat list

```json
{
  "seasons": null,
  "episodes": [
    { "id": "901", "season": 1, "episode_num": 1, "title": "Flat List Ep 1" },
    { "id": "902", "season": 1, "episode_num": 2, "title": "Flat List Ep 2" }
  ]
}
```

### 7.5 Episode fields the mapper reads

| Location | Keys |
| --- | --- |
| Stream id | `id`, `stream_id`, `episode_id` |
| Episode number | `episode_num`, `episode`, `num`, `info.episode_num` |
| Title | `info.name`, `title`, `name`, `info.title` |
| Container | `container_extension`, `info.container_extension`, `target_container` (default `mp4`) |
| Duration | `info.duration_secs`, `duration_secs`, or `HH:MM:SS` / `MM:SS` in `duration` |
| Plot | `info.plot`, `plot`, `info.overview` |
| Cover | `info.movie_image`, `info.cover`, `info.cover_big`, `movie_image`, `cover` |
| Season number | map key, or `season` / `season_num` / `season_number` on the episode |

Missing series: `{}` (app returns no seasons).

---

## 8. Short EPG — `get_short_epg`

**Available.** Not wired. Query: `action=get_short_epg&stream_id={id}` and optional `limit`.

```json
{
  "epg_listings": [
    {
      "id": "90001",
      "epg_id": "12",
      "title": "TW9ybmluZyBOZXdz",
      "lang": "en",
      "start": "2026-01-01 20:00:00",
      "end": "2026-01-01 21:00:00",
      "description": "TG9jYWwgbmV3cyBidWxsZXRpbg==",
      "channel_id": "beinsports1.qa",
      "start_timestamp": "1735761600",
      "stop_timestamp": "1735765200",
      "now_playing": 1,
      "has_archive": 0
    }
  ]
}
```

`title` and `description` are **Base64-encoded** on classic Xtream panels.

No EPG: `{ "epg_listings": [] }` or `[]`.

---

## 9. Full-day EPG — `get_simple_data_table`

**Defined** (`ApiConstants.actionGetSimpleDataTable`). Not called yet.

Query: `action=get_simple_data_table&stream_id={id}`

Same `epg_listings` array as §8, typically covering ~24 hours. Some panels add `now_playing` / `has_archive` on every row.

---

## 10. XMLTV guide — `xmltv.php`

**Available.** Not a `player_api` action.

```http
GET {server}/xmltv.php?username={user}&password={pass}
```

Response is XML (`application/xml` or `text/xml`), not JSON:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<tv>
  <channel id="beinsports1.qa">
    <display-name>beIN Sports 1 HD</display-name>
    <icon src="http://panel.example.com/images/bein1.png"/>
  </channel>
  <programme start="20260101200000 +0000" stop="20260101210000 +0000" channel="beinsports1.qa">
    <title>Morning News</title>
    <desc>Local news bulletin</desc>
  </programme>
</tv>
```

`channel id` matches live stream `epg_channel_id`.

---

## 11. M3U playlist — `get.php`

**Available** as a credential source (onboarding converter). Not used for catalog.

```http
GET {server}/get.php?username={user}&password={pass}&type=m3u_plus&output=ts
```

| Query | Values |
| --- | --- |
| `type` | `m3u_plus` (with extra tags) or `m3u` |
| `output` | `ts`, `m3u8`, `rtmp` |

Text playlist, not JSON:

```m3u
#EXTM3U
#EXTINF:-1 tvg-id="beinsports1.qa" tvg-name="beIN Sports 1 HD" tvg-logo="http://…" group-title="Sports",beIN Sports 1 HD
http://panel.example.com:8080/live/demo_user/demo_pass/4410.ts
#EXTINF:-1 tvg-id="" tvg-name="The Matrix" tvg-logo="http://…" group-title="Movies",The Matrix
http://panel.example.com:8080/movie/demo_user/demo_pass/5678.mp4
```

Failed auth is often a short HTML/text body or an empty playlist, still with HTTP 200.

---

## 12. Stream URLs (media, not JSON)

These are playback endpoints. Success is a media body (MPEG-TS, MP4, HLS playlist, Matroska). Failure is often HTTP 200 with a tiny HTML/XML error, or 404/403/302.

### 12.1 Live

```text
{server}/live/{user}/{pass}/{stream_id}.ts
{server}/live/{user}/{pass}/{stream_id}.m3u8
```

App default for catalog URL helper: `.ts`. Player `StreamResolver` default: `.m3u8`.

HLS body example:

```m3u
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:6
#EXTINF:6.0,
segment000.ts
#EXT-X-ENDLIST
```

(Live playlists usually omit `#EXT-X-ENDLIST` and keep appending segments.)

### 12.2 Movie (VOD)

```text
{server}/movie/{user}/{pass}/{stream_id}.{container_extension}
```

`container_extension` comes from `get_vod_streams` / `get_vod_info` (`mp4`, `mkv`, …).

### 12.3 Series episode

```text
{server}/series/{user}/{pass}/{episode_id}.{container_extension}
```

`episode_id` is the episode object `id`, not `series_id`.

### 12.4 Catch-up / timeshift

**Available.** Built when `tv_archive` is set.

```text
{server}/timeshift/{user}/{pass}/{duration}/{start}/{stream_id}.ts
```

| Segment | Meaning |
| --- | --- |
| `duration` | Minutes to record, e.g. `120` |
| `start` | `YYYY-MM-DD:HH-MM` in the panel timezone, e.g. `2026-01-01:20-00` |
| `stream_id` | Same as live |

Some panels also accept `.m3u8`.

### 12.5 Direct source

If a list item has a non-empty `direct_source`, that URL is the real stream (CDN, HLS, MPEG-TS). The `/live|movie|series/…` path may 404 or redirect.

---

## 13. HTTP / empty / error bodies (all actions)

Xtream panels rarely use REST status codes. Most catalog calls return **HTTP 200**.

| Body | Meaning |
| --- | --- |
| `[]` | Empty list (no categories/streams) |
| `{}` | Empty object; this app maps it to `[]` when a list was expected |
| `null` / `""` | Treated as empty |
| `{ "user_info": { "auth": 0 } }` | Returned from catalog actions on some panels when the session is invalid |
| HTML (`<!DOCTYPE html>…`) | Wrong host/port, Cloudflare challenge, or nginx error page |
| `{"error":"…"}` | Non-standard panels (XUI / XStreamity forks) |

HTTP layer (this app):

| Status | Mapping |
| --- | --- |
| `< 500` | Attempt JSON parse |
| `401` / `403` | Authentication error |
| `>= 500` | Server error |
| Timeout | Timeout error |
| DNS / TLS / connection refused | Network error |

---

## 14. Quick index

| Endpoint | Action / path | Response type | In this app |
| --- | --- | --- | --- |
| Auth + account | `player_api.php` (no action) | Object §1 | Used |
| Live categories | `get_live_categories` | Array §2 | Used |
| Live streams | `get_live_streams` | Array §3 | Used |
| VOD categories | `get_vod_categories` | Array §2 | Used |
| VOD streams | `get_vod_streams` | Array §4 | Used |
| VOD details | `get_vod_info` | Object §5 | Defined, unused |
| Series categories | `get_series_categories` | Array §2 | Used |
| Series list | `get_series` | Array §6 | Used |
| Series details | `get_series_info` | Object §7 | Used |
| Short EPG | `get_short_epg` | Object §8 | Available |
| Day EPG | `get_simple_data_table` | Object §9 | Defined, unused |
| XMLTV | `xmltv.php` | XML §10 | Available |
| M3U | `get.php` | Text §11 | Converter only |
| Live media | `/live/…` | TS / HLS §12.1 | Used |
| Movie media | `/movie/…` | File §12.2 | Used |
| Episode media | `/series/…` | File §12.3 | Used |
| Catch-up media | `/timeshift/…` | TS / HLS §12.4 | Available |

Code that performs these calls: `lib/data/datasources/xtream_remote_datasource.dart`. Field mapping: `lib/data/mappers/data_mapper.dart` and `lib/data/repositories/series_repository_impl.dart`. Auth parsing: `lib/data/repositories/auth_repository_impl.dart`.
