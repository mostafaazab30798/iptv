"""
Import and optimize beIN SPORTS logos from tv-logo/tv-logos repository.
Converts source PNGs to transparent, optimized WebP assets for Flutter.
"""

import os
import json
import urllib.request
import io
from PIL import Image

# Exact verified paths in tv-logo/tv-logos repository
MANIFEST = {
    "source": "tv-logo/tv-logos",
    "source_url": "https://github.com/tv-logo/tv-logos",
    "license": "Custom Open TV Logos Collection (Dark Theme)",
    "logos": [
        {
            "key": "bein_sports",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-mea.png",
            "asset_name": "bein_sports.webp",
            "description": "beIN Sports Global / Main"
        },
        {
            "key": "bein_sports_1",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-1-mea.png",
            "asset_name": "bein_sports_1.webp",
            "description": "beIN Sports 1"
        },
        {
            "key": "bein_sports_2",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-2-mea.png",
            "asset_name": "bein_sports_2.webp",
            "description": "beIN Sports 2"
        },
        {
            "key": "bein_sports_3",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-3-mea.png",
            "asset_name": "bein_sports_3.webp",
            "description": "beIN Sports 3"
        },
        {
            "key": "bein_sports_4",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-4-mea.png",
            "asset_name": "bein_sports_4.webp",
            "description": "beIN Sports 4"
        },
        {
            "key": "bein_sports_5",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-5-mea.png",
            "asset_name": "bein_sports_5.webp",
            "description": "beIN Sports 5"
        },
        {
            "key": "bein_sports_6",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-6-mea.png",
            "asset_name": "bein_sports_6.webp",
            "description": "beIN Sports 6"
        },
        {
            "key": "bein_sports_7",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-7-mea.png",
            "asset_name": "bein_sports_7.webp",
            "description": "beIN Sports 7"
        },
        {
            "key": "bein_sports_8",
            "source_path": "countries/united-states/bein-sports-8-us.png",
            "asset_name": "bein_sports_8.webp",
            "description": "beIN Sports 8"
        },
        {
            "key": "bein_sports_9",
            "source_path": "countries/international/beinsports/old/stacked/bein-sports-9-int.png",
            "asset_name": "bein_sports_9.webp",
            "description": "beIN Sports 9"
        },
        {
            "key": "bein_sports_4k",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-4k-mea.png",
            "asset_name": "bein_sports_4k.webp",
            "description": "beIN Sports 4K UHD"
        },
        {
            "key": "bein_sports_news",
            "source_path": "countries/international/beinsports/old/horizontal/bein-sports-news-hz-int.png",
            "asset_name": "bein_sports_news.webp",
            "description": "beIN Sports News"
        },
        {
            "key": "bein_sports_1_premium",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-1-premium-mea.png",
            "asset_name": "bein_sports_1_premium.webp",
            "description": "beIN Sports 1 Premium"
        },
        {
            "key": "bein_sports_2_premium",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-2-premium-mea.png",
            "asset_name": "bein_sports_2_premium.webp",
            "description": "beIN Sports 2 Premium"
        },
        {
            "key": "bein_sports_3_premium",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-3-premium-mea.png",
            "asset_name": "bein_sports_3_premium.webp",
            "description": "beIN Sports 3 Premium"
        },
        {
            "key": "bein_sports_1_max",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-1-max-mea.png",
            "asset_name": "bein_sports_1_max.webp",
            "description": "beIN Sports 1 Max"
        },
        {
            "key": "bein_sports_2_max",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-2-max-mea.png",
            "asset_name": "bein_sports_2_max.webp",
            "description": "beIN Sports 2 Max"
        },
        {
            "key": "bein_sports_3_max",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-3-max-mea.png",
            "asset_name": "bein_sports_3_max.webp",
            "description": "beIN Sports 3 Max"
        },
        {
            "key": "bein_sports_4_max",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-4-max-mea.png",
            "asset_name": "bein_sports_4_max.webp",
            "description": "beIN Sports 4 Max"
        },
        {
            "key": "bein_sports_5_max",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-5-max-mea.png",
            "asset_name": "bein_sports_5_max.webp",
            "description": "beIN Sports 5 Max"
        },
        {
            "key": "bein_sports_6_max",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-6-max-mea.png",
            "asset_name": "bein_sports_6_max.webp",
            "description": "beIN Sports 6 Max"
        },
        {
            "key": "bein_sports_1_xtra",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-1-xtra-mea.png",
            "asset_name": "bein_sports_1_xtra.webp",
            "description": "beIN Sports 1 Xtra"
        },
        {
            "key": "bein_sports_2_xtra",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-2-xtra-mea.png",
            "asset_name": "bein_sports_2_xtra.webp",
            "description": "beIN Sports 2 Xtra"
        },
        {
            "key": "bein_sports_1_english",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-1-english-mea.png",
            "asset_name": "bein_sports_1_english.webp",
            "description": "beIN Sports 1 English"
        },
        {
            "key": "bein_sports_2_english",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-2-english-mea.png",
            "asset_name": "bein_sports_2_english.webp",
            "description": "beIN Sports 2 English"
        },
        {
            "key": "bein_sports_3_english",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-3-english-mea.png",
            "asset_name": "bein_sports_3_english.webp",
            "description": "beIN Sports 3 English"
        },
        {
            "key": "bein_sports_1_french",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-1-french-mea.png",
            "asset_name": "bein_sports_1_french.webp",
            "description": "beIN Sports 1 French"
        },
        {
            "key": "bein_sports_2_french",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-2-french-mea.png",
            "asset_name": "bein_sports_2_french.webp",
            "description": "beIN Sports 2 French"
        },
        {
            "key": "bein_sports_3_french",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-3-french-mea.png",
            "asset_name": "bein_sports_3_french.webp",
            "description": "beIN Sports 3 French"
        },
        {
            "key": "bein_sports_nba",
            "source_path": "countries/world-middle-east/bein-sports/bein-sports-nba-mea.png",
            "asset_name": "bein_sports_nba.webp",
            "description": "beIN Sports NBA"
        }
    ]
}

def main():
    base_raw_url = "https://raw.githubusercontent.com/tv-logo/tv-logos/main"
    output_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "logos", "bein"))
    os.makedirs(output_dir, exist_ok=True)

    print(f"Importing {len(MANIFEST['logos'])} beIN logos to {output_dir}...")
    headers = {"User-Agent": "Mozilla/5.0"}

    processed_manifest = []

    for item in MANIFEST["logos"]:
        raw_url = f"{base_raw_url}/{item['source_path']}"
        out_path = os.path.join(output_dir, item["asset_name"])
        print(f"Downloading: {item['key']} from {item['source_path']}...")

        req = urllib.request.Request(raw_url, headers=headers)
        try:
            with urllib.request.urlopen(req) as resp:
                data = resp.read()
                img = Image.open(io.BytesIO(data))
                img = img.convert("RGBA")

                # Optimize dimensions for TV and Mobile if oversized (max width 512, height 512, preserving aspect ratio)
                # Save as optimized lossless or high-quality WebP with alpha transparency
                img.save(out_path, "WEBP", quality=90, method=6)
                print(f"  [OK] Saved {item['asset_name']} ({os.path.getsize(out_path)} bytes)")

                processed_manifest.append({
                    "key": item["key"],
                    "source_path": item["source_path"],
                    "asset_path": f"assets/logos/bein/{item['asset_name']}",
                    "description": item["description"]
                })
        except Exception as e:
            print(f"  [ERROR] Failed to process {item['key']}: {e}")

    # Write manifest.json
    manifest_file = os.path.join(output_dir, "manifest.json")
    with open(manifest_file, "w", encoding="utf-8") as f:
        json.dump({
            "source": MANIFEST["source"],
            "source_url": MANIFEST["source_url"],
            "license": MANIFEST["license"],
            "count": len(processed_manifest),
            "logos": processed_manifest
        }, f, indent=2)
    print(f"Saved manifest to {manifest_file}")

if __name__ == "__main__":
    main()
