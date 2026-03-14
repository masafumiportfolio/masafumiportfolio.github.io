"""
Instagram Follower Checker
--------------------------
自分のInstagramアカウントにログインし、
指定したユーザーが自分をフォローしているか確認するプログラムです。

使い方:
    python checker.py --username あなたのID --password パスワード --target 確認したいユーザーID

注意:
    - InstagramのToS（利用規約）に反する可能性があるため、自己責任でご使用ください。
    - パスワードはコマンドライン引数ではなく環境変数(.env)で渡すことを推奨します。
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
    parser = argparse.ArgumentParser(description="Instagram フォロワーチェッカー")
    parser.add_argument(
        "--username",
        default=os.getenv("IG_USERNAME"),
        help="あなたのInstagramユーザー名 (環境変数 IG_USERNAME でも指定可能)",
    )
    parser.add_argument(
        "--password",
        default=os.getenv("IG_PASSWORD"),
        help="あなたのInstagramパスワード (環境変数 IG_PASSWORD でも指定可能)",
    )
    parser.add_argument(
        "--target",
        default=os.getenv("IG_TARGET"),
        help="フォローしているか確認したいユーザーID (環境変数 IG_TARGET でも指定可能)",
    )
    parser.add_argument(
        "--headless",
        action="store_true",
        default=False,
        help="ブラウザを非表示で実行する (デフォルト: 表示あり)",
    )
    return parser.parse_args()


def login(page, username: str, password: str):
    """Instagramにログインする"""
    print(f"[1/4] Instagramにアクセス中...")
    page.goto(f"{INSTAGRAM_URL}/accounts/login/", wait_until="networkidle")

    # Cookieバナーを閉じる（表示された場合）
    try:
        page.click("text=すべてのCookieを許可", timeout=3000)
    except PlaywrightTimeoutError:
        pass
    try:
        page.click("text=Allow all cookies", timeout=3000)
    except PlaywrightTimeoutError:
        pass

    print(f"[2/4] ログイン中: {username}")
    page.fill('input[name="username"]', username)
    page.fill('input[name="password"]', password)
    page.click('button[type="submit"]')

    # ログイン完了を待つ
    try:
        page.wait_for_url(f"{INSTAGRAM_URL}/**", timeout=15000)
        # 「後で通知」ダイアログが出た場合に閉じる
        try:
            page.click("text=後で", timeout=5000)
        except PlaywrightTimeoutError:
            pass
        try:
            page.click("text=Not Now", timeout=3000)
        except PlaywrightTimeoutError:
            pass
        print("    ログイン成功!")
    except PlaywrightTimeoutError:
        print("    ログインに失敗しました。ユーザー名またはパスワードを確認してください。")
        sys.exit(1)


def get_follower_count(page, username: str) -> int:
    """プロフィールページからフォロワー数を取得する"""
    page.goto(f"{INSTAGRAM_URL}/{username}/", wait_until="networkidle")
    try:
        # フォロワー数のテキストを取得
        follower_el = page.locator('a[href*="/followers/"] span, a[href*="/followers"] span').first
        text = follower_el.inner_text(timeout=5000)
        # カンマや単位を除去して数値に変換
        text = text.replace(",", "").replace("万", "0000").replace("K", "000").strip()
        return int(float(text))
    except Exception:
        return -1


def check_follower(page, your_username: str, target_username: str) -> bool:
    """
    target_username があなたをフォローしているか確認する。
    自分のフォロワーリストを開いて target_username を検索する。
    """
    print(f"[3/4] あなたのプロフィールページへ移動中: {your_username}")
    page.goto(f"{INSTAGRAM_URL}/{your_username}/", wait_until="networkidle")
    time.sleep(1)

    # フォロワーリンクをクリック
    print(f"[4/4] フォロワーリストを確認中...")
    try:
        followers_link = page.locator(
            f'a[href="/{your_username}/followers/"], a[href*="/followers/"]'
        ).first
        followers_link.click(timeout=5000)
    except PlaywrightTimeoutError:
        # 直接URLで開く
        page.goto(f"{INSTAGRAM_URL}/{your_username}/followers/", wait_until="networkidle")

    # フォロワーダイアログが開くのを待つ
    time.sleep(2)

    # 検索ボックスで絞り込む
    try:
        search_input = page.locator(
            'input[placeholder*="検索"], input[placeholder*="Search"]'
        ).first
        search_input.fill(target_username, timeout=5000)
        time.sleep(2)
    except PlaywrightTimeoutError:
        print("    検索ボックスが見つかりませんでした。スクロールして確認します...")
        return scroll_and_find(page, target_username)

    # 検索結果に target_username が表示されているか確認
    result = page.locator(f'a[href="/{target_username}/"]').first
    try:
        result.wait_for(timeout=5000)
        return True
    except PlaywrightTimeoutError:
        return False


def scroll_and_find(page, target_username: str, max_scrolls: int = 50) -> bool:
    """
    フォロワーリストをスクロールしながら target_username を探す。
    フォロワー数が多い場合は時間がかかります。
    """
    for i in range(max_scrolls):
        # リスト内に target が存在するか確認
        result = page.locator(f'a[href="/{target_username}/"]').first
        if result.is_visible():
            return True
        # ダイアログをスクロール
        page.mouse.wheel(0, 600)
        time.sleep(0.5)
    return False


def main():
    args = parse_args()

    if not args.username or not args.password or not args.target:
        print(
            "エラー: --username, --password, --target を指定するか、"
            ".env ファイルに IG_USERNAME, IG_PASSWORD, IG_TARGET を設定してください。"
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
            is_following = check_follower(page, args.username, args.target)
        finally:
            browser.close()

    print("\n" + "=" * 50)
    if is_following:
        print(f"✅ @{args.target} はあなたをフォローしています！")
    else:
        print(f"❌ @{args.target} はあなたをフォローしていません。")
    print("=" * 50)


if __name__ == "__main__":
    main()
