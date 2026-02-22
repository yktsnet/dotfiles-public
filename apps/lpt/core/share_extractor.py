import sys
import os
import datetime
from pathlib import Path
import time
import re

if "PLAYWRIGHT_BROWSERS_PATH" in os.environ:
    os.environ["PLAYWRIGHT_BROWSERS_PATH"] = os.environ.get("PLAYWRIGHT_BROWSERS_PATH")

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("Error: 'playwright' library is required.")
    sys.exit(1)


def get_shared_content(url):
    with sync_playwright() as p:
        try:
            browser = p.chromium.launch(headless=True)
            context = browser.new_context(
                locale="ja-JP",
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            )
            page = context.new_page()

            print(f"Loading page: {url} ...")

            page.goto(url, wait_until="domcontentloaded", timeout=60000)

            try:
                page.wait_for_selector(
                    ".message-content", state="visible", timeout=30000
                )
            except Exception:
                print("Warning: Content selector timeout. Trying to capture anyway...")

            last_height = 0
            for i in range(10):
                page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                time.sleep(2)

                new_height = page.evaluate("document.body.scrollHeight")
                if new_height == last_height:
                    break
                last_height = new_height

            title = page.title()
            if "Gemini" in title:
                try:
                    h1 = page.locator("h1.conversation-title, h1").first
                    if h1.is_visible():
                        t_text = h1.inner_text().strip()
                        if t_text:
                            title = t_text
                except:
                    pass

            title = title.replace(" - Gemini", "").strip()

            msgs = page.evaluate(
                """() => {
                const results = [];
                const selectors = [
                    'message-content', 
                    '.message-content', 
                    '.query-text', 
                    '.response-text', 
                    '.model-response-text'
                ];
                
                const containers = document.querySelectorAll(selectors.join(', '));
                
                if (containers.length > 0) {
                    containers.forEach(el => {
                        if (el.offsetParent === null) return;
                        const text = el.innerText.trim();
                        if (text) {
                            let role = "Content";
                            if (el.classList.contains('query-text') || el.closest('.user-query-container')) {
                                role = "User";
                            } else if (el.classList.contains('response-text') || el.classList.contains('model-response-text') || el.closest('.model-response-container')) {
                                role = "Gemini";
                            }
                            results.push({role: role, text: text});
                        }
                    });
                } else {
                    const main = document.querySelector('main');
                    if (main) {
                        results.push({role: "FullPage_Main", text: main.innerText});
                    }
                }
                return results;
            }"""
            )

            browser.close()
            return title, msgs

        except Exception as e:
            print(f"Browser Error: {e}")
            return None, []


def clean_filename(title):
    safe = re.sub(r'[\\/*?:"<>|]', "_", title)
    safe = safe.replace("\n", "").replace("\r", "")
    return safe[:100]


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 share_extractor.py <URL>")
        return

    url = sys.argv[1]

    result = get_shared_content(url)
    if not result:
        print("Failed.")
        return

    title, data = result
    if not data:
        print("Content is empty.")
        return

    home = Path.home()
    dst_dir = home / "Downloads"
    dst_dir.mkdir(parents=True, exist_ok=True)

    safe_title = clean_filename(title)
    if not safe_title:
        safe_title = "Gemini_Shared_Chat"

    now = datetime.datetime.now()
    ts = now.strftime("%Y%m%d_%H%M")

    filename = f"log_{safe_title}_{ts}.txt"
    out_path = dst_dir / filename

    try:
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(f"Title: {title}\n")
            f.write(f"Source: {url}\n")
            f.write(f"Date: {now.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("=" * 40 + "\n\n")

            for item in data:
                role = item.get("role", "Content")
                text = item.get("text", "")
                f.write(f"[{role}]\n")
                f.write("-" * len(role) + "\n")
                f.write(f"{text}\n\n")
                f.write("=" * 40 + "\n\n")

        print(f"Successfully saved to: {out_path}")
    except Exception as e:
        print(f"File Write Error: {e}")


if __name__ == "__main__":
    main()
