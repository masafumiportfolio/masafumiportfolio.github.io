# 筋トレ記録アプリ セットアップガイド

## 前提条件

- Mac (macOS 13 以上推奨)
- Xcode 15 以上
- Android Studio
- Flutter SDK 3.16 以上

---

## Step 1: Flutter SDK のインストール

```bash
# Homebrew でインストール
brew install flutter

# バージョン確認
flutter --version

# 環境チェック
flutter doctor
```

---

## Step 2: このプロジェクトをセットアップ

```bash
# このフォルダをコピーして Mac に配置後
cd workout_tracker

# 依存関係インストール
flutter pub get

# コード生成（Drift DB用）
dart run build_runner build --delete-conflicting-outputs
```

---

## Step 3: Firebase プロジェクトの作成

1. [Firebase Console](https://console.firebase.google.com/) を開く
2. 「プロジェクトを追加」→ プロジェクト名: `workout-tracker`
3. **Authentication** を有効化
   - 「Sign-in method」→「メール/パスワード」を有効にする
4. **Firestore Database** を有効化
   - 「本番環境モード」で作成
   - ルールは後で設定

---

## Step 4: Firebase CLI でアプリと連携

```bash
# Firebase CLI インストール
npm install -g firebase-tools

# FlutterFire CLI インストール
dart pub global activate flutterfire_cli

# ログイン
firebase login

# アプリと Firebase を連携（iOSとAndroid両方設定）
flutterfire configure --project=YOUR_PROJECT_ID
```

このコマンドを実行すると `lib/firebase_options.dart` が自動生成されます。

---

## Step 5: main.dart の修正

`firebase_options.dart` が生成されたら `main.dart` を更新:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ← 追加
  );
  runApp(const ProviderScope(child: WorkoutTrackerApp()));
}
```

---

## Step 6: Firestore セキュリティルール

Firebase Console → Firestore → ルール に以下を設定:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Step 7: iOS 設定

```bash
cd ios
pod install
cd ..
```

`ios/Runner/Info.plist` に日本語ロケール設定を追加:
```xml
<key>CFBundleLocalizations</key>
<array>
  <string>ja</string>
</array>
```

---

## Step 8: 実行

```bash
# iOS シミュレーターで実行
flutter run -d ios

# Android エミュレーターで実行
flutter run -d android

# 接続デバイス一覧
flutter devices
```

---

## App Store / Google Play リリース

### iOS (App Store)
1. Apple Developer Program に加入 ($99/年)
2. Xcode でアーカイブ作成: `Product → Archive`
3. App Store Connect にアップロード
4. 審査提出

### Android (Google Play)
1. Google Play Developer アカウント作成 ($25 初回のみ)
2. 署名付き APK / AAB を生成:
   ```bash
   flutter build appbundle --release
   ```
3. Google Play Console にアップロード
4. 審査提出

---

## プロジェクト構成

```
lib/
├── main.dart                    # エントリーポイント
├── models/
│   ├── exercise.dart            # DBテーブル定義
│   └── app_database.dart        # Driftデータベース
├── screens/
│   ├── auth/
│   │   ├── auth_gate.dart       # 認証ゲート
│   │   └── login_screen.dart    # ログイン画面
│   ├── home/
│   │   └── home_screen.dart     # ホーム画面
│   ├── workout/
│   │   ├── workout_screen.dart  # トレーニング記録画面
│   │   └── add_exercise_sheet.dart # 種目追加シート
│   └── history/
│       └── history_screen.dart  # 履歴・進捗画面
└── services/                    # Firebase連携サービス（今後追加）
```
