import argparse
import json
import os
import sys
from datetime import datetime
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


def fetch_today_matches(output_path: str = DEFAULT_OUTPUT, target_date: str = None) -> list:
    """
    Fetches matches from Yallakora match center and writes sanitized static JSON.
    target_date format if provided: MM/DD/YYYY
    """
    date_str = target_date or datetime.now().strftime("%m/%d/%Y")
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

                scores = m_result.find_all("span", class_="score") if m_result else []
                score_a = scores[0].text.strip() if len(scores) > 0 else "-"
                score_b = scores[1].text.strip() if len(scores) > 1 else "-"

                status_div = match.find("div", class_="matchStatus")
                status = status_div.text.strip() if status_div else ""

                channel_div = match.find("div", class_="channel")
                channel = channel_div.text.strip() if channel_div else "Not Available"

                matches_data.append({
                    "league": league,
                    "team_home": team_a,
                    "team_away": team_b,
                    "logo_home": logo_a,
                    "logo_away": logo_b,
                    "score_home": score_a,
                    "score_away": score_b,
                    "time": time,
                    "status": status,
                    "channel": channel,
                })

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
