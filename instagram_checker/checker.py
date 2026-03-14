"""
Instagram フォローバックチェッカー
-----------------------------------
自分がフォローしているのに、フォローバックされていないアカウントを一覧表示します。

使い方:
    python checker.py

    または:
    python checker.py --username あなたのID --password パスワード

注意:
    - パスワードは .env ファイルで管理することを推奨します。
    - Instagramの利用規約に抵触する可能性があるため、自己責任でご使用ください。
"""

import argparse
import os
import sys
import time
from dotenv import load_dotenv
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeoutError

load_dotenv()

INSTAGRAM_URL = "https://www.instagram.com"


def parse_args():
    parser = argparse.ArgumentParser(description="Instagram フォローバックチェッカー")
    parser.add_argument("--username", default=os.getenv("IG_USERNAME"))
    parser.add_argument("--password", default=os.getenv("IG_PASSWORD"))
    parser.add_argument("--headless", action="store_true", default=False)
    return parser.parse_args()


def close_dialogs(page):
    """通知許可・Cookie等のダイアログを閉じる"""
    for text in ["後で", "Not Now", "すべてのCookieを許可", "Allow all cookies"]:
        try:
            page.click(f"text={text}", timeout=2000)
        except PlaywrightTimeoutError:
            pass


def login(page, username: str, password: str):
    print("Instagram にログイン中...")
    page.goto(f"{INSTAGRAM_URL}/accounts/login/", wait_until="networkidle")
    close_dialogs(page)

    page.fill('input[name="username"]', username)
    page.fill('input[name="password"]', password)
    page.click('button[type="submit"]')

    try:
        page.wait_for_selector('svg[aria-label="ホーム"], svg[aria-label="Home"]', timeout=15000)
        close_dialogs(page)
        print("ログイン成功!\n")
    except PlaywrightTimeoutError:
        print("ログインに失敗しました。ID・パスワードを確認してください。")
        sys.exit(1)


def scroll_list_to_end(page, dialog_selector: str) -> list[str]:
    """
    フォロー/フォロワーのダイアログをスクロールして全ユーザー名を取得する。
    返り値: ユーザー名のリスト
    """
    collected = set()
    last_count = 0
    no_change_count = 0

    while True:
        # 現在表示されているユーザー名リンクを取得
        links = page.locator(f"{dialog_selector} a[href^='/'][role='link']").all()
        for link in links:
            href = link.get_attribute("href") or ""
            username = href.strip("/")
            if username and "/" not in username:
                collected.add(username)

        print(f"  取得中... {len(collected)} 件", end="\r")

        if len(collected) == last_count:
            no_change_count += 1
            if no_change_count >= 4:
                break
        else:
            no_change_count = 0

        last_count = len(collected)

        # ダイアログ内をスクロール
        dialog = page.locator(dialog_selector).first
        page.evaluate("(el) => el.scrollTop = el.scrollHeight", dialog.element_handle())
        time.sleep(1)

    print()
    return list(collected)


def get_user_list(page, username: str, list_type: str) -> list[str]:
    """
    list_type: "following" または "followers"
    """
    label = "フォロー中" if list_type == "following" else "フォロワー"
    print(f"{label}リストを取得中...")

    page.goto(f"{INSTAGRAM_URL}/{username}/", wait_until="networkidle")
    time.sleep(1)

    # リンクをクリックしてダイアログを開く
    try:
        page.click(f'a[href="/{username}/{list_type}/"]', timeout=5000)
    except PlaywrightTimeoutError:
        page.goto(f"{INSTAGRAM_URL}/{username}/{list_type}/", wait_until="networkidle")

    time.sleep(2)

    # ダイアログのスクロール可能な要素を特定
    dialog_selector = 'div[role="dialog"] > div > div:last-child > div > div'

    users = scroll_list_to_end(page, dialog_selector)
    print(f"  → {len(users)} 件取得完了\n")
    return users


def main():
    args = parse_args()

    if not args.username or not args.password:
        print(
            "エラー: .env ファイルに IG_USERNAME と IG_PASSWORD を設定するか、\n"
            "--username と --password を指定してください。"
        )
        sys.exit(1)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=args.headless)
        context = browser.new_context(
            viewport={"width": 1280, "height": 800},
            user_agent=(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/120.0.0.0 Safari/537.36"
            ),
            locale="ja-JP",
        )
        page = context.new_page()

        try:
            login(page, args.username, args.password)

            following = set(get_user_list(page, args.username, "following"))
            followers = set(get_user_list(page, args.username, "followers"))
        finally:
            browser.close()

    # フォローバックされていないアカウント = 自分がフォロー & 相手がフォローしていない
    not_following_back = sorted(following - followers)

    print("=" * 50)
    print(f"フォローしているのにフォローバックされていないアカウント: {len(not_following_back)} 件")
    print("=" * 50)
    for i, user in enumerate(not_following_back, 1):
        print(f"{i:>4}. @{user}  (https://www.instagram.com/{user}/)")

    # 結果をファイルにも保存
    output_file = "not_following_back.txt"
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(f"フォローバックされていないアカウント一覧 ({len(not_following_back)} 件)\n")
        f.write("=" * 50 + "\n")
        for user in not_following_back:
            f.write(f"@{user}\thttps://www.instagram.com/{user}/\n")

    print(f"\n結果を {output_file} にも保存しました。")


if __name__ == "__main__":
    main()
