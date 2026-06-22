# Idea Sync Server

Ruby + Hanami 2.3 による **アイデア管理 + AI 壁打ち REST API**。DDD Lite アーキテクチャで構築した、アイデア共有プラットフォームのバックエンド。

## 技術スタック

- **フレームワーク**: Hanami 2.3
- **認証**: JWT（Base64URL + HMAC-SHA256 手動実装）
- **AI**: Google Gemini API（`gemini-3.1-flash-lite`）でアイデア壁打ち
- **Webサーバー**: Puma 6（API）／ Falcon（WebSocket・導入中）
- **データベース**: PostgreSQL 16
- **ORM**: Sequel（全リポジトリで**単一の共有接続プール**を使用 → [lib/hanami_auth_app/database.rb](lib/hanami_auth_app/database.rb)）
- **主キー**: UUIDv7（時系列順・列挙耐性）
- **API**: REST（JSON）＋ WebSocket（リアルタイム・作業中）
- **コンテナ**: Docker / Docker Compose
- **言語**: Ruby 3.2

## 特徴

- ✅ **API ファースト** — JSON レスポンスのみ（フロント独立）
- ✅ **DDD Lite アーキテクチャ** — ドメイン層 → アプリケーション層 → インフラ層
- ✅ **JWT 認証** — Bearer token で API 保護
- ✅ **ロール** — `user` / `admin`（DB が真実。リクエスト毎に参照）
- ✅ **所有権チェック** — 各リソースは本人のみアクセス可（他人のものは 403）
- ✅ **UUIDv7 主キー** — 連番 ID の列挙攻撃に対する多層防御
- ✅ **AI 壁打ち** — Gemini と 1 アイデア 1 セッションで対話、ログを永続化

## リアルタイム / WebSocket（作業中）

グローバルチャットを **ポーリング → WebSocket** へ移行中。現状は **まだポーリング**（チャットは10秒間隔で取得）で、WebSocket は未完成。

これまでの調査結果（次回の前提）:

- **Falcon を導入し、API が Falcon でも動くようにした。** Falcon の `rack.input` は非巻き戻し(streaming)で `request.body.read` が空になるため、ボディを `StringIO` にバッファする `RewindableInput` ミドルウェアを追加（[lib/hanami_auth_app/rewindable_input.rb](lib/hanami_auth_app/rewindable_input.rb)）。これで POST/PATCH も Falcon で正常動作。
- **WebSocket をHanamiのミドルウェアとして挟む方式は不採用。** `async-websocket` の Rack アダプタ（`Async::WebSocket::Adapters::Rack.open`）は「`run` する単独アプリ」前提で、Hanami のミドルウェアスタックに挟むとアップグレード要求がハンドラまで dispatch されない。
- **次の一手**: WebSocket を **独立した Falcon プロセス**（別ポート、`run lambda { … }` の単独 Rack アプリ）として切り出し、`JWT_SECRET` 共有・同一DBで運用する。API は Puma のまま。
- 認証は **httpOnly Cookie の `auth_token`** をハンドシェイクから読む（[lib/hanami_auth_app/websocket_handler.rb](lib/hanami_auth_app/websocket_handler.rb) に実装済み・単独プロセス化待ち）。

> 現状の `config.ru` には WebsocketHandler が暫定でミドルウェアとして載っているが、上記の通り単独プロセスへ移す予定。API（Puma/Falcon とも）の動作には影響しない。

## クイックスタート

```bash
cd idea_sync_server
docker compose up -d   # マイグレーションも自動実行
```

ローカルで直接動かす場合:

```bash
bundle install
# .env.local に DATABASE_URL / GEMINI_API_KEY / JWT_SECRET を設定
bundle exec hanami db create && bundle exec hanami db migrate
bundle exec puma -p 2300
```

### 必要な環境変数

| 変数 | 用途 |
|------|------|
| `DATABASE_URL` | PostgreSQL 接続文字列 |
| `GEMINI_API_KEY` | Gemini API キー（AI 壁打ち用） |
| `JWT_SECRET` | JWT 署名鍵（本番では必須・ランダム値） |

## API エンドポイント

### 認証

| メソッド | URL | 説明 |
|---------|-----|------|
| `POST` | `/api/accounts` | ユーザー登録 → JWT token |
| `POST` | `/api/login` | ログイン → JWT token |
| `GET` | `/api/me` | 現在のユーザー情報 `{account_id, email, role}` を返す |

`/api/me` の `role` は **DB から都度取得**するため、ロール変更（昇格/降格）が即座に反映される。

### Idea CRUD（Bearer 認証 + 所有権チェック）

| メソッド | URL | ステータス | 説明 |
|---------|-----|-----------|------|
| `GET` | `/api/ideas` | 200 | アイデア一覧（自分のもののみ） |
| `POST` | `/api/ideas` | 201 | 新規作成 |
| `GET` | `/api/ideas/:id` | 200/403/404 | 詳細（他人のものは 403） |
| `PATCH` | `/api/ideas/:id` | 200/403/404 | 更新（他人のものは 403） |
| `DELETE` | `/api/ideas/:id` | 204/403/404 | 削除（他人のものは 403） |

### AI 壁打ち（Gemini・Bearer 認証 + 所有権チェック）

| メソッド | URL | 説明 |
|---------|-----|------|
| `GET` | `/api/ai_chat/sessions?idea_id=:id` | アイデアのセッションを取得（無ければ作成） |
| `GET` | `/api/ai_chat/sessions/:session_id/messages` | 会話ログ取得 |
| `POST` | `/api/ai_chat/sessions/:session_id/messages` | メッセージ送信 → Gemini 応答を保存して返す |

1 アイデア = 1 セッション。セッション・メッセージともに所有者のみアクセス可。

### グローバルチャット

| メソッド | URL | 説明 |
|---------|-----|------|
| `GET` | `/api/messages` | 全メッセージ取得（最新順・全ユーザー共有） |
| `POST` | `/api/messages` | メッセージ作成 |

**Idea / AI チャット / `/api/me` は Bearer token で保護されています。**

```bash
curl -H "Authorization: Bearer <JWT_TOKEN>" http://localhost:2300/api/ideas
```

## ロールについて

`accounts.role` に `user` / `admin` を持つ（デフォルト `user`、CHECK 制約あり）。
最初の管理者は DB から直接昇格させる（ローカル管理者の想定）:

```sql
UPDATE accounts SET role = 'admin' WHERE email = 'you@example.com';
```

会議・参加者ごとの **機能ロール**（タイムキーパー / 進行 / 書記 / 発表）は今後追加予定。

## ディレクトリ構成

```
idea_sync_server/
├── lib/hanami_auth_app/
│   ├── domain/                   # ドメイン層（エンティティ・Repository IF）
│   │   ├── account/              #   Account（id, email, role）
│   │   ├── idea/                 #   Idea
│   │   └── ai_chat/              #   AiChatSession / AiChatMessage
│   ├── jwt_auth.rb               # JWT（Base64URL + HMAC-SHA256）
│   ├── gemini_client.rb          # Gemini API クライアント
│   └── uuid7.rb                  # UUIDv7 生成（RFC 9562）
├── app/
│   ├── usecases/                 # アプリケーション層（操作）
│   ├── repos/                    # インフラ層（Sequel 実装・uuid 生成）
│   └── actions/api/
│       ├── accounts/             # 登録 / ログイン
│       ├── me/                   # GET /api/me
│       ├── ideas/                # Idea CRUD（所有権チェック）
│       ├── ai_chat/              # AI 壁打ち
│       └── messages/             # グローバルチャット
├── config/{app.rb,routes.rb,db/migrate/}
├── Dockerfile
└── docker-compose.yml
```

## 使用例

### 1. ユーザー登録 → JWT token

```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}' \
  http://localhost:2300/api/accounts

# 201 Created
{
  "status": "success",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "account": { "id": "019ec9e1-2d5b-7463-ab58-9549cbd7d2cf", "email": "user@example.com" }
}
```

### 2. 現在のユーザー情報（ロール込み）

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:2300/api/me

# 200 OK
{ "account_id": "019ec9e1-...", "email": "user@example.com", "role": "user" }
```

### 3. アイデア詳細（所有権チェック）

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:2300/api/ideas/<uuid>

# 本人 (200 OK)
{ "id": "019ec9e5-...", "account_id": "019ec9e1-...", "title": "...", "description": "...", "created_at": "...", "updated_at": "..." }

# 他人のアイデア (403 Forbidden)
{ "error": "Forbidden" }

# 存在しない (404 Not Found)
{ "error": "Idea not found" }
```

### 4. AI 壁打ち

```bash
# セッション取得（idea_id 指定）
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:2300/api/ai_chat/sessions?idea_id=<idea_uuid>"

# メッセージ送信 → Gemini 応答
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"body":"このアイデアの弱点は？"}' \
  http://localhost:2300/api/ai_chat/sessions/<session_uuid>/messages
```

## エラーレスポンス

```bash
{ "error": "Missing or invalid authorization header" }  # 401
{ "error": "Invalid token" }                             # 401
{ "error": "Forbidden" }                                 # 403（他人のリソース）
{ "error": "Idea not found" }                            # 404
{ "error": "..." }                                       # 500
```

## 認証の仕組み

```
Header (JSON)  → Base64URL encode
Payload (JSON: account_id, iat) → Base64URL encode
Signature      → HMAC-SHA256(header.payload, JWT_SECRET) → Base64URL encode
Token = header.payload.signature
```

- `JWT_SECRET` は `ENV['JWT_SECRET']`、未設定時は dev 用デフォルト。**本番では必ず設定**。
- 現状トークンに有効期限（`exp`）は無い。
- `account_id` は UUIDv7。ロールはトークンに含めず、毎リクエスト DB から取得する。

## 開発フロー

```bash
docker compose up -d        # 起動
docker compose logs -f app  # ログ
docker compose restart app  # 再起動（変更反映）
docker compose down         # 停止
```

## 次のステップ

- [ ] 会議（meetings）テーブルと参加者・機能ロール
- [ ] 認証処理の共通化（AuthenticatedAction 基底）
- [ ] 機能ロールの Policy / 権限マトリクス
- [ ] WebSocket の会議スコープ化
- [ ] ユニット / 統合テストの拡充

## 参考

- [ARCHITECTURE.md](ARCHITECTURE.md) — DDD Lite 設計ガイド
- [Hanami ガイド](https://guides.hanamirb.org/)
- [JWT 仕様](https://tools.ietf.org/html/rfc7519)
- [UUIDv7 (RFC 9562)](https://www.rfc-editor.org/rfc/rfc9562)
