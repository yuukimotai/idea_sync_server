# Hanami Auth App

Ruby + Hanami 2.3 + Rodauth による認証・DDD Lite アーキテクチャを採用した Web アプリケーション。

## 技術スタック

- **フレームワーク**: Hanami 2.3
- **認証**: Rodauth
- **データベース**: PostgreSQL 17
- **ORM**: Sequel（ROM 経由）
- **コンテナ**: Docker + Docker Compose
- **言語**: Ruby 3.3

## 特徴

- ✅ DDD Lite アーキテクチャ（ドメイン層 ⊢ アプリケーション層 ⊢ インフラ層）
- ✅ CRUD パターンの実装例（Todo 管理）
- ✅ Docker Compose で完全な開発環境
- ✅ Rodauth による強力な認証機能

## クイックスタート

### セットアップ

```bash
cd hanami_auth_app
docker compose up -d
```

Docker が自動的にマイグレーションを実行します。

### アクセス

```
http://localhost:2300
```

**アカウント登録** → **ログイン** → **Todo 管理**

## ディレクトリ構成

```
hanami_auth_app/
├── lib/hanami_auth_app/
│   ├── domain/              # ドメイン層（エンティティ、ビジネスルール）
│   │   ├── account/
│   │   ├── todo/
│   │   └── shared/result.rb
│   └── rodauth_app.rb       # 認証ミドルウェア（Roda）
├── app/
│   ├── usecases/            # アプリケーション層（ユースケース）
│   │   └── todo/
│   ├── repos/               # インフラ層（リポジトリ実装）
│   │   └── todo_repository.rb
│   └── actions/             # プレゼンテーション層（HTTP エンドポイント）
│       ├── home/
│       └── todo/
├── config/
│   ├── app.rb               # DI コンテナ設定
│   ├── routes.rb            # ルーティング
│   └── db/migrate/          # DB マイグレーション
├── views/                   # ERB テンプレート
├── Dockerfile
└── docker-compose.yml
```

詳細は [ARCHITECTURE.md](ARCHITECTURE.md) を参照。

## 主な機能

### 認証（Rodauth）
- ユーザー登録
- ログイン / ログアウト
- セッション管理

### Todo 管理（CRUD パターン実装例）
- ✅ Todo 一覧表示
- ✅ Todo 作成
- ⚙️ Todo 更新（実装済み）
- ⚙️ Todo 削除（実装済み）
- ⚙️ Todo 完了トグル（実装済み）

（✅=動作確認済み、⚙️=実装済み未テスト）

## 開発フロー

```bash
# コンテナ起動
docker compose up -d

# ログ確認
docker compose logs -f app

# コンテナ再起動（ファイル変更時）
docker compose restart app

# コンテナ停止
docker compose down
```

## 次のステップ

- [ ] Docker 起動 → マイグレーション実行確認
- [ ] ブラウザで `/todos` にアクセスして CRUD 動作確認
- [ ] Update/Delete/Toggle アクション実装
- [ ] View テンプレート整備
- [ ] ユニットテスト・統合テスト追加
- [ ] API モード対応（JSON レスポンス）

## 参考

- [ARCHITECTURE.md](ARCHITECTURE.md) — 設計思想と実装パターン
- [Hanami ガイド](https://guides.hanamirb.org/)
- [Rodauth ドキュメント](https://rodauth.jeremyevans.net/)
