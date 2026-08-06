#!/usr/bin/env python3
"""
githubtrending.py
Fetches the top repositories from GitHub Trending page and posts a summary
to a Telegram Bot.
"""

import html as html_mod, json, os, urllib.request
from html.parser import HTMLParser

# Resolve Telegram credentials from environment variables
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID", "")

TRENDING_URL = "https://github.com/trending"


class TrendingParser(HTMLParser):
    """
    HTML parser to extract repository name, URL, and description
    from the GitHub Trending page's DOM structure.
    """
    def __init__(self):
        super().__init__()
        self.repos = []
        self._in_h2 = False
        self._in_p = False
        self._current_repo = None
        self._depth = 0

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self._depth += 1
        # Each trending repository is wrapped in an <article> tag
        if tag == "article":
            self._current_repo = {"name": "", "url": "", "description": ""}
        if self._current_repo is not None:
            if tag == "h2":
                self._in_h2 = True
            # The repository link is an <a> tag inside an <h2> tag
            if tag == "a" and self._in_h2:
                href = attrs.get("href", "")
                if href.count("/") == 2:
                    self._current_repo["url"] = "https://github.com" + href
                    self._current_repo["name"] = href.lstrip("/")
            # The description is usually wrapped in a <p> tag
            if tag == "p":
                self._in_p = True

    def handle_endtag(self, tag):
        if tag == "h2":
            self._in_h2 = False
        if tag == "p":
            self._in_p = False
        # Push the parsed repository object to the list when the <article> tag ends
        if tag == "article" and self._current_repo:
            if self._current_repo["url"]:
                self.repos.append(self._current_repo)
            self._current_repo = None
        self._depth -= 1

    def handle_data(self, data):
        # Accumulate description text
        if self._current_repo and self._in_p:
            text = data.strip()
            if text:
                self._current_repo["description"] += text


# Fetch the GitHub trending HTML page
with urllib.request.urlopen(
    urllib.request.Request(TRENDING_URL, headers={"User-Agent": "curl/7.88.1"})
) as res:
    html = res.read().decode("utf-8", errors="replace")

# Parse HTML to find the top repos
parser = TrendingParser()
parser.feed(html)
repos = parser.repos[:3] # Keep only the top 3 repos
print(f"trending: {len(repos)} repos")
for r in repos:
    print(f"  {r['name']} - {r['description'][:50]}")


def post_telegram(content):
    """
    Posts the formatted content to a configured Telegram Bot.
    """
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        print("telegram: not configured")
        return
    payload = json.dumps({
        "chat_id": TELEGRAM_CHAT_ID,
        "text": content,
        "parse_mode": "HTML",
        "disable_web_page_preview": True
    }).encode("utf-8")

    url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    req = urllib.request.Request(
        url,
        data=payload,
        headers={"content-type": "application/json"},
    )
    with urllib.request.urlopen(req) as resp:
        resp.read()
    print("telegram: ok")


# Prepare Telegram message text
lines = ["🔥 <b>GitHub Trending TOP 3</b>"]
for i, r in enumerate(repos, 1):
    desc = html_mod.escape(r["description"].strip() or "（説明なし）")
    name = html_mod.escape(r["name"])
    url = html_mod.escape(r["url"])
    lines.append(f"{i}. <b>{name}</b>\n{desc}\n{url}")

post_telegram("\n\n".join(lines))
