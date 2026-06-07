# Idea Sync Server

Ruby + Hanami 2.3 による **Idea 管理 REST API**。DDD Lite アーキテクチャで構築した、アイデア共有・管理プラットフォームのバックエンド。

## 技術スタック

- **フレームワーク**: Hanami 2.3
- **認証**: Rodauth
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
- ✅ **Rodauth** による認証

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

すべてのエンドポイントは Rodauth セッションで保護されています。

**登録/ログイン** は `hanami_auth_app` 側で行います（別アプリ）。

## ディレクトリ構成

```
idea_sync_server/
├── lib/hanami_auth_app/
│   ├── domain/              # ドメイン層
│   │   ├── account/
│   │   ├── idea/            # ← Idea エンティティ
│   │   └── shared/result.rb
│   └── rodauth_app.rb       # 認証ミドルウェア
├── app/
│   ├── usecases/
│   │   └── idea/            # ← Idea CRUD UseCase
│   ├── repos/
│   │   └── idea_repository.rb  # ← Sequel 実装
│   └── actions/
│       └── api/
│           └── ideas/       # ← REST API Actions
├── config/
│   ├── app.rb
│   ├── routes.rb
│   └── db/migrate/
├── Dockerfile
└── docker-compose.yml
```

## 使用例

### 一覧取得

```bash
curl -H "Cookie: _hanami_auth_app_session=..." \
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

### 作成

```bash
curl -X POST \
  -H "Cookie: _hanami_auth_app_session=..." \
  -H "Content-Type: application/json" \
  -d '{"title":"AI活用","description":"..."}' \
  http://localhost:2300/api/ideas

# レスポンス (201 Created)
{
  "idea": {
    "id": 2,
    "title": "AI活用",
    ...
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

## 参考

- [ARCHITECTURE.md](ARCHITECTURE.md) — DDD Lite 設計と API パターン
- [Hanami ガイド](https://guides.hanamirb.org/)
- [Rodauth ドキュメント](https://rodauth.jeremyevans.net/)
