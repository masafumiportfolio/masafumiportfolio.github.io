# Instagram フォロワーチェッカー

指定したユーザーが自分のInstagramアカウントをフォローしているか自動確認するツールです。

## セットアップ

### 1. 依存ライブラリのインストール

```bash
cd instagram_checker
pip install -r requirements.txt
playwright install chromium
```

### 2. 認証情報の設定

`.env.example` をコピーして `.env` を作成し、値を入力します。

```bash
cp .env.example .env
```

`.env` を編集:
```
IG_USERNAME=your_instagram_username
IG_PASSWORD=your_password
IG_TARGET=target_username_to_check
```

## 使い方

### .env ファイルを使う場合（推奨）

```bash
python checker.py
```

### コマンドライン引数で指定する場合

```bash
python checker.py --username あなたのID --password パスワード --target 確認したいID
```

### ブラウザを非表示（ヘッドレス）で実行する場合

```bash
python checker.py --headless
```

## 実行例

```
[1/4] Instagramにアクセス中...
[2/4] ログイン中: your_username
    ログイン成功!
[3/4] あなたのプロフィールページへ移動中: your_username
[4/4] フォロワーリストを確認中...

==================================================
✅ @target_user はあなたをフォローしています！
==================================================
```

## 注意事項

- **セキュリティ**: パスワードはコマンドライン引数ではなく `.env` ファイルで管理してください。`.env` はGitにコミットされません。
- **利用規約**: Instagramの自動アクセスは利用規約に抵触する可能性があります。自己責任でご使用ください。
- **2段階認証**: 2段階認証が有効な場合、ログイン時に手動での操作が必要になることがあります（`--headless` を使わずに実行してください）。
- **フォロワー数**: フォロワーが非常に多い場合は検索ボックスを使った絞り込みが有効です。
