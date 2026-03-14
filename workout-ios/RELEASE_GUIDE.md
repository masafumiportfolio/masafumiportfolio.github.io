# 筋トレ記録アプリ - App Store リリースガイド

## 必要なもの
- **Mac** (macOS 13 以上推奨)
- **Xcode 15 以上**（Mac App Store から無料でインストール）
- **Apple Developer アカウント**（https://developer.apple.com/ 年額99ドル）
- **Node.js 18 以上**（https://nodejs.org/ から無料でインストール）

---

## STEP 1: このフォルダを Mac にコピー

```bash
# このリポジトリを Mac にクローン
git clone https://github.com/masafumiportfolio/masafumiportfolio.github.io.git
cd masafumiportfolio.github.io/workout-ios
```

---

## STEP 2: 依存関係のインストール

```bash
npm install
```

---

## STEP 3: iOS プロジェクトを生成

```bash
# Capacitor に iOS プラットフォームを追加
npx cap add ios

# Web ファイルを iOS プロジェクトに同期
npx cap copy ios
```

実行後、`ios/` フォルダが生成されます。

---

## STEP 4: アプリアイコンを作成

1. **1024x1024px** の正方形 PNG アイコンを用意する（背景透過なし）
   - おすすめツール: Figma（無料）, Canva
   - デザイン案: 青いダンベルのアイコン（色: #1E88E5）

2. `www/icons/` フォルダを作成してアイコンを配置:
   ```
   www/icons/
   ├── icon-180.png   (180x180)
   ├── icon-192.png   (192x192)
   ├── icon-512.png   (512x512)
   └── icon-1024.png  (1024x1024)
   ```

3. CapacitorのアイコンツールでXcode用のアイコンセットを生成:
   ```bash
   npm install -g @capacitor/assets
   npx capacitor-assets generate --ios
   ```

   または Xcode の AppIcon に直接ドラッグ&ドロップ

---

## STEP 5: Xcode でプロジェクトを開く

```bash
npx cap open ios
```

---

## STEP 6: Xcode での設定

### Bundle Identifier
1. 左側の **App** → **Targets > App** → **Signing & Capabilities**
2. `com.masafumiportfolio.workouttracker` が設定されていることを確認

### チームの設定
1. **Team** のドロップダウンから自分のApple IDを選択
2. 「Automatically manage signing」にチェック

### アプリバージョン
- **Version**: `1.0.0`
- **Build**: `1`

### スプラッシュスクリーン（任意）
`ios/App/App/Assets.xcassets/Splash.imageset` に画像を配置

---

## STEP 7: 実機テスト

1. iPhone を Mac に USB で接続
2. Xcode 上部のデバイス選択で iPhone を選択
3. `▶️ Run` ボタンで起動
4. iPhone で動作確認

---

## STEP 8: App Store Connect の設定

1. https://appstoreconnect.apple.com/ にアクセス
2. **「マイ App」→ 「+」→ 「新規App」**
3. 以下を入力:
   - **プラットフォーム**: iOS
   - **名前**: 筋トレ記録
   - **プライマリ言語**: 日本語
   - **Bundle ID**: com.masafumiportfolio.workouttracker
   - **SKU**: workout-tracker-2026

---

## STEP 9: スクリーンショットを撮影

App Store 審査に必要なスクリーンショット（Xcode Simulator で撮影可）:
- **iPhone 6.9インチ** (iPhone 16 Pro Max): 1320 × 2868 px - 必須
- **iPhone 6.5インチ** (iPhone 14 Plus): 1242 × 2688 px - 必須
- **iPhone 5.5インチ** (iPhone 8 Plus): 1242 × 2208 px - 推奨

撮影する画面:
1. ホーム画面（カレンダー + 統計）
2. トレーニング記録画面（種目入力中）
3. 履歴画面
4. 進捗グラフ画面

---

## STEP 10: ビルドのアーカイブ

1. Xcode 上部のデバイス選択で **「Any iOS Device (arm64)」** を選択
2. メニューから **Product → Archive**
3. Organizer ウィンドウが開いたら **「Distribute App」**
4. **「App Store Connect」** を選択 → **「Upload」**

---

## STEP 11: App Store Connect でメタデータ入力

App Store Connect で審査に必要な情報を入力:

| 項目 | 内容 |
|------|------|
| アプリ名 | 筋トレ記録 |
| サブタイトル | トレーニングを記録・管理 |
| カテゴリ | ヘルスケア / フィットネス |
| 年齢制限 | 4+ |
| 価格 | 無料（または有料） |

**アプリ説明文（例）**:
```
筋トレの記録・管理に特化したシンプルなアプリです。

【主な機能】
• カレンダーでトレーニング日を視覚管理
• 種目別に重量・回数・セット数を記録
• 今週の回数・セット数・連続記録を表示
• 種目ごとの最高重量推移グラフ
• データはすべてデバイスに保存（通信不要）

【収録種目（34種目）】
胸・背中・脚・肩・腕・腹筋のメジャーな種目を収録。
検索機能でかんたんに種目を選択できます。
```

**キーワード**（10個まで、コンマ区切り）:
```
筋トレ,トレーニング,ワークアウト,記録,重量,筋肉,フィットネス,ジム,ボディビル,健康
```

---

## STEP 12: プライバシーポリシーの準備

App Store 審査には**プライバシーポリシーの URL** が必要です。

簡単な作成方法:
1. https://www.freeprivacypolicy.com/ 等で無料生成
2. GitHub Pages の別ページに掲載（例: `masafumiportfolio.github.io/privacy`）

ポイント:
- このアプリはデータをデバイス内にのみ保存し、外部送信しないことを明記

---

## STEP 13: 審査提出

1. App Store Connect で全項目入力完了後、**「審査へ提出」**
2. 審査期間: 通常 **24〜48時間**（初回は最大1週間かかる場合あり）
3. 審査通過後、**自動または手動で公開**

---

## よくある審査リジェクト対策

| リジェクト理由 | 対策 |
|------|------|
| スクリーンショットが不鮮明 | Simulator で高解像度を確認 |
| プライバシーポリシーなし | URLを必ず設定 |
| 機能が少なすぎる | 説明文で価値を明確に伝える |
| クラッシュ | 実機で十分テスト後に提出 |

---

## アップデート手順（リリース後）

```bash
# コードを修正後
npx cap copy ios     # Web ファイルを更新
npx cap sync ios     # プラグインも更新（パッケージ追加時）
# Xcode でバージョン番号を上げてアーカイブ → 提出
```

---

## お問い合わせ

問題が発生した場合は Apple Developer Forums: https://developer.apple.com/forums/
または Capacitor 公式: https://capacitorjs.com/docs/ios
