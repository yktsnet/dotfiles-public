#!/usr/bin/env python3
"""
hatenadigest.py
Fetches articles from the Hatena Bookmark IT category RSS feed, uses Anthropic's Claude AI
to filter articles relevant to AI and development, and posts the digest to a Telegram Bot.
"""

import html, json, os, re, urllib.request, xml.etree.ElementTree as ET

# Fetch API key and Telegram credentials from environment variables
API_KEY = os.environ.get("ANTHROPIC_API_KEY", "")
TELEGRAM_BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.environ.get("TELEGRAM_CHAT_ID", "")

RSS_URL = "https://b.hatena.ne.jp/hotentry/it.rss"
NS = {
    "rss": "http://purl.org/rss/1.0/",
    "dc": "http://purl.org/dc/elements/1.1/",
}

# 前日URLの読み込み
HATEBU_DIR = os.path.expanduser("~/.local/share/hatebu")
LAST_URLS_FILE = os.path.join(HATEBU_DIR, "last_urls.txt")

prev_urls = set()
if os.path.exists(LAST_URLS_FILE):
    with open(LAST_URLS_FILE) as f:
        prev_urls = {line.strip() for line in f if line.strip()}

# Fetch and parse the RSS feed from Hatena Bookmark
with urllib.request.urlopen(RSS_URL) as res:
    root = ET.parse(res).getroot()

lines = []
url_map = {}

# Process each item in the RSS feed
hatebu_count = 0
for item in root.findall("rss:item", NS):
    if hatebu_count >= 20:
        break
    url = item.find("rss:link", NS).text or ""
    if url in prev_urls:
        continue
    title = item.find("rss:title", NS).text or ""
    tags = [
        s.text
        for s in item.findall("dc:subject", NS)
        if s.text and s.text != "テクノロジー"
    ]
    short_title = title[:15]
    url_map[short_title] = (title, url, "はてブ")
    lines.append(f"{short_title} {url} [{', '.join(tags)}]")
    hatebu_count += 1

# ── Zenn ──────────────────────────────────────────────────────────────
ZENN_URL = "https://zenn.dev/api/articles?order=daily&count=30"
with urllib.request.urlopen(ZENN_URL) as res:
    zenn_data = json.loads(res.read().decode())

zenn_count = 0
for article in zenn_data.get("articles", []):
    if zenn_count >= 20:
        break
    url = f"https://zenn.dev{article.get('path', '')}"
    if url in prev_urls:
        continue
    title = article.get("title", "")
    topics = [t["name"] for t in article.get("topics", [])]
    short_title = title[:15]
    url_map[short_title] = (title, url, "Zenn")
    lines.append(f"{short_title} {url} [{', '.join(topics)}]")
    zenn_count += 1

article_list = "\n".join(lines)
print(f"articles: {len(lines)} (はてブ:{hatebu_count} Zenn:{zenn_count})")

# Instruct Claude to filter only AI/Development related articles from the list
PROMPT = (
    "以下ははてブ・Zennの記事一覧。AIや開発に関連する記事だけ選べ。\n"
    '形式: {"items":[{"title":"...","url":"..."}]}\n'
    'titleは入力のまま返せ。文字列内の"はエスケープせよ。JSONのみ出力。説明不要。\n\n'
    + article_list
)

payload = json.dumps(
    {
        "model": "claude-haiku-4-5",
        "max_tokens": 4096,
        "messages": [{"role": "user", "content": PROMPT}],
    }
).encode()

# Make request to Anthropic's Claude API
req = urllib.request.Request(
    "https://api.anthropic.com/v1/messages",
    data=payload,
    headers={
        "x-api-key": API_KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
        "User-Agent": "curl/7.88.1",
    },
)
with urllib.request.urlopen(req) as res:
    result = json.loads(res.read().decode())

text = result["content"][0]["text"]
print(f"response: {text}")

# Extract JSON response from the LLM output using regex
m = re.search(r"\{.*\}", text, re.DOTALL)
if not m:
    print("ERROR: parse failed")
    exit(1)

raw = m.group()
try:
    items = json.loads(raw).get("items", [])
except json.JSONDecodeError:
    raw = re.sub(r'(?<!\\)"(?=[^:,\[\]{}])', '\\"', raw)
    try:
        items = json.loads(raw).get("items", [])
    except json.JSONDecodeError:
        print("ERROR: parse failed")
        exit(1)

print(f"filtered: {len(items)}")

# 今日のURLを保存
os.makedirs(HATEBU_DIR, exist_ok=True)
with open(LAST_URLS_FILE, "w") as f:
    for line in lines:
        url = line.split(" ")[1]
        f.write(url + "\n")


def post_telegram(content):
    """
    Sends the digest content to a Telegram Bot.
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


# Prepare Telegram message
lines_telegram = ["📰 <b>はてブ AI/開発 digest</b>"]
for item in items:
    short = item.get("title", "")
    full_title, url, source = url_map.get(short, (short, item.get("url", ""), ""))
    title_esc = html.escape(full_title)
    source_esc = html.escape(source)
    url_esc = html.escape(url)
    lines_telegram.append(f"• [{source_esc}] <b>{title_esc}</b>\n{url_esc}")

# Send in chunks that don't exceed Telegram's 4096 character limit
message = ""
for line in lines_telegram:
    if len(message) + len(line) + 2 > 4000:
        post_telegram(message)
        message = line
    else:
        if message:
            message += "\n\n" + line
        else:
            message = line

if message:
    post_telegram(message)
