# Idea Sync Server

Ruby + Hanami 2.3 による **Idea 管理 REST API**。DDD Lite アーキテクチャで構築した、アイデア共有・管理プラットフォームのバックエンド。

## 技術スタック

- **フレームワーク**: Hanami 2.3
- **認証**: JWT（Base64 + HMAC-SHA256 手動実装）
- **データベース**: PostgreSQL 17
- **ORM**: Sequel（ROM 経由）
- **API**: REST（JSON）
- **コンテナ**: Docker + Docker Compose
- **言語**: Ruby 3.3

## 特徴

- ✅ **API ファースト** — JSON レスポンスのみ（フロント独立）
- ✅ **DDD Lite アーキテクチャ** — ドメイン層 ⊢ アプリケーション層 ⊢ インフラ層
- ✅ **CRUD パターン実装例** — Idea 管理機能
- ✅ **Docker Compose** で完全な開発環境
- ✅ **JWT 認証** — Bearer token で API 保護

## クイックスタート

### セットアップ

```bash
cd idea_sync_server
docker compose up -d
```

Docker が自動的にマイグレーションを実行します。

### API エンドポイント

```
http://localhost:2300/api/ideas
```

## API エンドポイント

### Idea CRUD

| メソッド | URL | 説明 |
|---------|-----|------|
| `GET` | `/api/ideas` | アイデア一覧（自分のアイデアのみ） |
| `POST` | `/api/ideas` | 新規アイデア作成 |
| `PATCH` | `/api/ideas/:id` | アイデア更新 |
| `DELETE` | `/api/ideas/:id` | アイデア削除 |

### 認証

| メソッド | URL | 説明 |
|---------|-----|------|
| `POST` | `/api/accounts` | ユーザー登録 → JWT token |
| `POST` | `/api/login` | ログイン → JWT token |

**すべての Idea エンドポイントは Bearer token で保護されています。**

```bash
curl -H "Authorization: Bearer <JWT_TOKEN>" \
  http://localhost:2300/api/ideas
```

## ディレクトリ構成

```
idea_sync_server/
├── lib/hanami_auth_app/
│   ├── domain/              # ドメイン層
│   │   ├── account/         # ← Account エンティティ
│   │   ├── idea/            # ← Idea エンティティ
│   │   └── shared/result.rb
│   └── jwt_auth.rb          # ← JWT 認証（Base64 + HMAC-SHA256）
├── app/
│   ├── usecases/
│   │   ├── account/         # ← Account CRUD UseCase
│   │   └── idea/            # ← Idea CRUD UseCase
│   ├── repos/
│   │   ├── account_repository.rb  # ← Account Sequel 実装
│   │   └── idea_repository.rb     # ← Idea Sequel 実装
│   └── actions/
│       └── api/
│           ├── accounts/    # ← 登録/ログイン
│           └── ideas/       # ← REST API Actions
├── config/
│   ├── app.rb
│   ├── routes.rb
│   └── db/migrate/
├── Dockerfile
└── docker-compose.yml
```

## 使用例

### 1. ユーザー登録 → JWT token 取得

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}' \
  http://localhost:2300/api/accounts

# レスポンス (201 Created)
{
  "status": "success",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "account": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

### 2. アイデア一覧取得（JWT 認証）

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:2300/api/ideas

# レスポンス
{
  "ideas": [
    {
      "id": 1,
      "title": "新しいWebサービス",
      "description": "...",
      "created_at": "2025-06-07T...",
      "updated_at": "2025-06-07T..."
    }
  ]
}
```

### 3. ログイン → 新しい token 取得

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}' \
  http://localhost:2300/api/login

# レスポンス
{
  "status": "success",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "account": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

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
- [ ] `curl` で API テスト（CRUD 確認）
- [ ] Postman/Insomnia で API 検証
- [ ] WebSocket 対応（リアルタイム更新）
- [ ] タグ/カテゴリ機能追加
- [ ] ユニットテスト・統合テスト追加
- [ ] ユーザー間コラボレーション機能

## 認証の仕組み

JWT は以下の流れで生成・検証されます：

```
Header (JSON)  → Base64URL encode
Payload (JSON) → Base64URL encode
Signature      → HMAC-SHA256(header.payload, SECRET) → Base64URL encode

Token = header.payload.signature
```

**Secret キー**は `ENV['JWT_SECRET']` または デフォルト `"dev-secret-key-change-in-production"` で、本番環境では必ず変更してください。

## 参考

- [ARCHITECTURE.md](ARCHITECTURE.md) — DDD Lite 設計と API パターン
- [Hanami ガイド](https://guides.hanamirb.org/)
- [JWT 仕様](https://tools.ietf.org/html/rfc7519)
