"""excel-kanri app デモ録画: login → 新規作成モーダル → 生成 → 自動プレビュー → 検索

再生成手順（リポルートで実行。docker compose up -d --build で app が :8000 に起動していること）:
  python3 docs/record-app-demo.py --dry-run   # 場面スクショのみ（録画なし）。ロケータ検証用
  python3 docs/record-app-demo.py             # 本録画（dry-run が全場面 OK になってから）
  ffmpeg -i docs/video/*.webm -vf "fps=10,scale=960:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" -loop 0 docs/app-demo.gif

playwright / ブラウザ未整備の環境では:
  nix-shell -p python3Packages.playwright playwright-driver.browsers --run \
    'export PLAYWRIGHT_BROWSERS_PATH=$(nix-build "<nixpkgs>" -A playwright-driver.browsers --no-out-link); \
     python3 docs/record-app-demo.py'
"""
import sys
import time
from playwright.sync_api import sync_playwright

OUT_DIR = "docs/video"  # 実行後: ffmpeg で GIF 化（上記 docstring 参照）
DRY = "--dry-run" in sys.argv

_snap_n = 0

def snap(page, name):
    """dry-run 時のみ、場面の切れ目でスクショを撮る"""
    global _snap_n
    if DRY:
        _snap_n += 1
        page.screenshot(path=f"{OUT_DIR}/dryrun-{_snap_n:02d}-{name}.png")

def pause(sec):
    """演出用の間。dry-run では待たない"""
    if not DRY:
        time.sleep(sec)

def slow_type(page, selector, text):
    page.click(selector)
    page.type(selector, text, delay=45)

with sync_playwright() as p:
    # PDF ビューア描画のためヘッド付き必須（headless では preview が白紙になる）
    browser = p.chromium.launch(headless=False)
    ctx_opts = {"viewport": {"width": 1280, "height": 800}}
    if not DRY:
        ctx_opts["record_video_dir"] = OUT_DIR
        ctx_opts["record_video_size"] = {"width": 1280, "height": 800}
    ctx = browser.new_context(**ctx_opts)
    page = ctx.new_page()
    page.goto("http://localhost:8000")
    page.wait_for_selector("text=ログイン")
    snap(page, "login")
    pause(1.2)

    # editor タブでログイン（デモ認証情報が自動入力される）
    page.click("button:has-text('編集者')")
    pause(1.0)
    page.click("button[type=submit]:has-text('ログイン')")
    page.wait_for_selector("text=としてログイン中")
    snap(page, "logged-in")
    pause(1.8)

    # 新規作成モーダル
    page.click("button:has-text('新規作成')")
    page.wait_for_selector("text=書類生成")
    pause(1.0)

    labels = {
        "applicant_name": "山田 太郎",
        "room_number": "302",
        "move_in_date": "2026-08-01",
        "phone": "090-1234-5678",
        "emergency_contact": "山田 花子 080-9876-5432",
    }
    modal = page.locator("div.fixed.inset-0")
    inputs = modal.locator("input[type=text]")
    for i, (_, value) in enumerate(labels.items()):
        inputs.nth(i).click()
        inputs.nth(i).type(value, delay=40)
    snap(page, "modal-filled")
    pause(0.8)

    modal.locator("button[type=submit]:has-text('生成')").click()
    # モーダルが閉じるまで待つ（成功時に閉じて自動プレビューされる）
    page.wait_for_selector("div.fixed.inset-0", state="detached", timeout=30000)
    # dry-run でも PDF プレビューの描画完了を待ってから撮る
    time.sleep(2.0 if DRY else 3.5)
    snap(page, "preview")

    # 検索 → 結果クリック
    search = page.locator("input[placeholder*='検索']")
    search.click()
    search.type("302", delay=60)
    page.click("button:has-text('検索')")
    pause(1.5)
    page.locator("li button").first.click()
    time.sleep(2.0 if DRY else 3.0)
    snap(page, "search-hit")

    ctx.close()
    browser.close()
print("done (dry-run)" if DRY else "done")
