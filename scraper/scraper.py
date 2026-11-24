import argparse
import json
import os
import sys
from datetime import datetime, timedelta, timezone
import requests
from bs4 import BeautifulSoup

DEFAULT_OUTPUT = "matches.json"
YALLAKORA_URL = "https://www.yallakora.com/match-center"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "ar,en;q=0.9",
}


def sanitize_url(url: str) -> str:
    if not url:
        return ""
    # Fix escaped Windows backslashes in image paths
    cleaned = url.replace("\\", "/").strip()
    if cleaned.startswith("//"):
        cleaned = f"https:{cleaned}"
    return cleaned


# Yallakora renders match times in Cairo Standard Time (UTC+2) when scraped
# from non-Egyptian servers (such as GitHub Actions in UTC).
YALLAKORA_SOURCE_TZ = timezone(timedelta(hours=2))


def convert_source_time_to_utc(time_str: str, base_date: datetime) -> tuple[str, str]:
    """
    Converts a Yallakora match time ("HH:MM" in UTC+2) into:
    - time_utc: "HH:MM" in Universal Time (UTC)
    - kickoff_utc: ISO-8601 UTC timestamp ("YYYY-MM-DDTHH:MM:00Z")
    """
    cleaned = (time_str or "").strip()
    parts = cleaned.split(":")
    if len(parts) < 2:
        return "00:00", ""
    try:
        hour = int(parts[0].strip())
        minute = int(parts[1].strip())
    except ValueError:
        return "00:00", ""

    source_dt = datetime(
        base_date.year,
        base_date.month,
        base_date.day,
        hour,
        minute,
        tzinfo=YALLAKORA_SOURCE_TZ,
    )
    utc_dt = source_dt.astimezone(timezone.utc)
    return utc_dt.strftime("%H:%M"), utc_dt.strftime("%Y-%m-%dT%H:%M:%SZ")


def fetch_today_matches(output_path: str = DEFAULT_OUTPUT, target_date: str = None) -> list:
    """
    Fetches matches from Yallakora match center and writes sanitized static JSON.
    target_date format if provided: MM/DD/YYYY
    """
    now_source = datetime.now(YALLAKORA_SOURCE_TZ)
    if target_date:
        try:
            base_date = datetime.strptime(target_date, "%m/%d/%Y")
        except ValueError:
            base_date = now_source
        date_str = target_date
    else:
        base_date = now_source
        date_str = now_source.strftime("%m/%d/%Y")
    url = f"{YALLAKORA_URL}/?date={date_str}"

    print(f"Fetching matches from: {url}")
    matches_data = []

    try:
        response = requests.get(url, headers=HEADERS, timeout=15)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, "html.parser")

        cards = soup.find_all("div", class_="matchCard")
        print(f"Discovered {len(cards)} tournament cards.")

        for card in cards:
            title_container = card.find("div", class_="title")
            h2 = title_container.find("h2") if title_container else card.find("h2")
            league = h2.text.strip() if h2 else "Unknown League"

            # Match items are styled as 'liItem' or 'item'
            match_items = card.find_all("div", class_="liItem")
            if not match_items:
                match_items = card.find_all("div", class_="item")

            for match in match_items:
                team_a_el = match.find("div", class_="teamA")
                team_b_el = match.find("div", class_="teamB")

                team_a = (
                    team_a_el.find("p").text.strip()
                    if (team_a_el and team_a_el.find("p"))
                    else "Unknown"
                )
                team_b = (
                    team_b_el.find("p").text.strip()
                    if (team_b_el and team_b_el.find("p"))
                    else "Unknown"
                )

                img_a = team_a_el.find("img") if team_a_el else None
                img_b = team_b_el.find("img") if team_b_el else None
                logo_a = sanitize_url(img_a.get("src", "") if img_a else "")
                logo_b = sanitize_url(img_b.get("src", "") if img_b else "")

                m_result = match.find("div", class_="MResult")
                time_el = m_result.find("span", class_="time") if m_result else None
                time = time_el.text.strip() if time_el else "00:00"
                time_utc, kickoff_utc = convert_source_time_to_utc(time, base_date)

                scores = m_result.find_all("span", class_="score") if m_result else []
                score_a = scores[0].text.strip() if len(scores) > 0 else "-"
                score_b = scores[1].text.strip() if len(scores) > 1 else "-"

                status_div = match.find("div", class_="matchStatus")
                status = status_div.text.strip() if status_div else ""

                channel_div = match.find("div", class_="channel")
                channel = channel_div.text.strip() if channel_div else "Not Available"

                match_entry = {
                    "league": league,
                    "team_home": team_a,
                    "team_away": team_b,
                    "logo_home": logo_a,
                    "logo_away": logo_b,
                    "score_home": score_a,
                    "score_away": score_b,
                    "time": time,
                    "time_utc": time_utc,
                    "timezone_offset": 2,
                    "status": status,
                    "channel": channel,
                }
                if kickoff_utc:
                    match_entry["kickoff_utc"] = kickoff_utc
                matches_data.append(match_entry)

        parent_dir = os.path.dirname(os.path.abspath(output_path))
        if parent_dir and not os.path.exists(parent_dir):
            os.makedirs(parent_dir, exist_ok=True)

        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(matches_data, f, ensure_ascii=False, indent=2)

        # Keep services/matches_api/matches.json synchronized if directory exists
        services_api_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "services",
            "matches_api",
            "matches.json",
        )
        if os.path.exists(os.path.dirname(services_api_path)):
            with open(services_api_path, "w", encoding="utf-8") as f:
                json.dump(matches_data, f, ensure_ascii=False, indent=2)

        print(f"Successfully scraped and exported {len(matches_data)} matches to {output_path}.")
        return matches_data

    except Exception as e:
        print(f"Error scraping matches: {e}", file=sys.stderr)
        # Ensure a valid JSON array exists even on failure
        if not os.path.exists(output_path):
            with open(output_path, "w", encoding="utf-8") as f:
                json.dump([], f)
        return []


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Scrape daily football matches from Yallakora.")
    parser.add_argument("--output", "-o", default=DEFAULT_OUTPUT, help="Output JSON path")
    parser.add_argument("--date", "-d", default=None, help="Target date in MM/DD/YYYY format")
    args = parser.parse_args()

    fetch_today_matches(output_path=args.output, target_date=args.date)
