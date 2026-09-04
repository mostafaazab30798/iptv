# Matches API Service (`matches.hope-tv.site`)

This service powers the matches endpoint for HOPE TV at `https://matches.hope-tv.site`.

## How it works
1. When clients call `GET /` or `GET /matches.json`, it fetches the latest scraped `matches.json` from the repository with Cloudflare Edge caching (5 minutes TTL).
2. Sets full CORS headers (`Access-Control-Allow-Origin: *`) to enable web, desktop, and mobile playback.
3. Automatically reflects daily match updates produced by the `.github/workflows/daily_scraper.yml` workflow without requiring manual redeployment.

## Deployment Options

### Option 1: Cloudflare Dashboard (Instant - 1 minute)
1. Go to your Cloudflare Dashboard -> **Workers & Pages**.
2. Select your Worker or Pages project attached to `matches.hope-tv.site`.
3. Open the code editor (or **Edit code**).
4. Replace the default "Hello World" template with the content of `_worker.js`.
5. Click **Deploy**.

### Option 2: Deploy via Wrangler CLI
From this directory:
```bash
npx wrangler deploy
```

### Option 3: Cloudflare Pages (Git Connected)
If connecting this repository to Cloudflare Pages:
- **Build output directory**: `services/matches_api`
- **Root directory**: `services/matches_api`
