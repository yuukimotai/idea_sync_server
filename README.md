# Idea Sync Server

Ruby + Hanami 2.3 による **アイデア管理 + AI 壁打ち REST API**。DDD Lite アーキテクチャで構築した、アイデア共有プラットフォームのバックエンド。

## 技術スタック

- **フレームワーク**: Hanami 2.3
- **認証**: JWT（Base64URL + HMAC-SHA256 手動実装）
- **AI**: Google Gemini API（`gemini-3.1-flash-lite`）でアイデア壁打ち
- **Webサーバー**: Hanami（HTTP API）／ Falcon（WebSocket 専用プロセス・別ポート）
- **データベース**: PostgreSQL 16
- **ORM**: Sequel（全リポジトリで**単一の共有接続プール**を使用 → [lib/hanami_auth_app/database.rb](lib/hanami_auth_app/database.rb)）
- **主キー**: UUIDv7（時系列順・列挙耐性）
- **API**: REST（JSON）＋ WebSocket（リアルタイム）
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
- ✅ **WebSocket リアルタイムチャット** — Falcon 複数プロセス（`:3001`）でグローバル＆会議室チャットを WS 専用サーバーとして分離。Redis pub/sub でプロセス間ブロードキャスト

## リアルタイム / WebSocket

グローバルチャットと会議室チャットを **WebSocket** でリアルタイム双方向通信する。HTTP API（Hanami）と **プロセスを分離**して Falcon 単体で動作させている。

### アーキテクチャ

```
ブラウザ ──WS── Falcon :3001 (cable.ru, --count 2)  ← WS 専用・複数プロセス
                 ├ プロセスA ─┐
                 └ プロセスB ─┴─ Redis pub/sub（プロセス間ブロードキャスト）
ブラウザ ──HTTP─ Hanami :2300                        ← REST API プロセス
```

**分離の理由**: `async-websocket` の Rack アダプタは Falcon（async I/O）上でのみ正しく動く。Hanami の通常 HTTP スタックに混在させると 101 Upgrade が正常にディスパッチされないため、WS だけ Falcon の単独プロセスに切り出した。

### 認証

WS ハンドシェイク時に `?token=<JWT>` クエリパラメータで認証する。クライアント（Next.js）は httpOnly Cookie に保存された JWT を `/api/ws-token` サーバーサイドルート経由で取得し、WS URL に付与する。

### チャンネルスコープ

WS 接続は **グローバル** または **会議室単位** にスコープされる。

| WS URL | チャンネル |
|--------|----------|
| `/cable?token=<JWT>` | グローバルチャット（全員共有） |
| `/cable?token=<JWT>&room_code=<12文字>` | 会議室チャット（ルームコード単位で分離） |

### ブロードキャスト（複数プロセス対応）

各プロセスは自分にぶら下がる接続だけをレジストリ（`Hash<room_key, Set>` + `Mutex`）で持ち、配信は `ws_broadcaster.rb` に委譲する:

| `REDIS_URL` | Broadcaster | 挙動 |
|-------------|-------------|------|
| あり | `RedisBroadcaster` | `PUBLISH` → 全プロセス（自分含む）が購読で受信し、各自のローカル接続へ書き込む。`--count 2` 以上で必須 |
| なし | `LocalBroadcaster` | プロセス内直接配信のみ（`--count 1` 専用） |

- Redis 購読タスクは接続受付時に遅延起動（プロセスごとに1本、WS と同じ reactor 上で動くため書き込み競合なし）
- Sequel は `fiber_concurrency` 拡張を有効化。async 環境で複数 fiber が同時にクエリしても fiber ごとに別接続が割り当たる
- 会議室チャットのメッセージは `messages.meeting_id`（UUID FK、null = グローバル）で区別され DB に永続化される

## クイックスタート

**事前準備**: `.env.local` に `GEMINI_API_KEY` を設定する（AI 壁打ち用）:

```env
# .env.local（gitignore 済み）
GEMINI_API_KEY=your_api_key_here
```

```bash
cd idea_sync_server
docker compose up -d
# → app(:2300) / ws(:3001, 2プロセス) / client(:3000) / redis(:6380) / db(:5433) が一括起動
# → DB マイグレーションも自動実行
# → .env.local の GEMINI_API_KEY が app コンテナに自動で渡される
```

ブラウザで `http://localhost:3000` にアクセスすれば使い始められる。

ローカルで直接動かす場合:

```bash
bundle install
# .env.local に DATABASE_URL / GEMINI_API_KEY / JWT_SECRET を設定
bundle exec hanami db create && bundle exec hanami db migrate

# 開発時は foreman 等で Procfile.dev をまとめて起動
bundle exec foreman start -f Procfile.dev

# または個別に起動
bundle exec hanami server                                              # :2300
bundle exec falcon serve --count 1 --bind tcp://localhost:3001 --config cable.ru  # :3001（Redis なし単プロセス）
REDIS_URL=redis://localhost:6379 bundle exec falcon serve --count 2 --bind tcp://localhost:3001 --config cable.ru  # 複数プロセス
```

### 必要な環境変数

| 変数 | 用途 |
|------|------|
| `DATABASE_URL` | PostgreSQL 接続文字列 |
| `GEMINI_API_KEY` | Gemini API キー（AI 壁打ち用） |
| `JWT_SECRET` | JWT 署名鍵（HTTP API・WS 両プロセスで共有。本番では必須） |
| `REDIS_URL` | Redis 接続文字列（WS 複数プロセス時に必須。未設定ならプロセス内配信のみ） |
| `DB_MAX_CONNECTIONS` | Sequel 接続プール上限（デフォルト 10） |

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
| `GET` | `/api/ideas` | 200 | アイデア一覧（自分のもののみ）。`?q=` でタイトル・説明の部分一致検索（大文字小文字区別なし）、`?sort=created_at\|updated_at\|title`・`?order=asc\|desc` で並び替え |
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

| メソッド | URL | サーバー | 説明 |
|---------|-----|---------|------|
| `GET` | `/api/messages` | Hanami :2300 | 全メッセージ取得（最新順・全ユーザー共有） |
| `WS` | `/cable?token=<JWT>` | Falcon :3001 | リアルタイム送受信（JWT クエリ認証） |

### 会議（Bearer 認証）

| メソッド | URL | 説明 |
|---------|-----|------|
| `POST` | `/api/meetings` | 会議部屋を作成 → `{meeting: {..., passcode}}` |
| `GET` | `/api/meetings/:id` | 会議詳細取得 |
| `POST` | `/api/meetings/:id/join` | パスコードで入室 → `{meeting, participant}` |
| `GET` | `/api/meetings/:id/messages` | 会議室のチャット履歴取得（最新50件） |
| `WS` | `/cable?token=<JWT>&room_code=<code>` | Falcon :3001 | 会議室リアルタイムチャット |

会議部屋には **ルームコード**（12文字英数字）と **パスコード**（6文字）の2つが発行される。入室は UUID ではなくルームコードで行う。

**リクエスト例（会議作成）**:
```bash
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"title":"朝のブレスト","purpose":"brainstorm"}' \
  http://localhost:2300/api/meetings
# purpose: "ideation" | "refinement" | "brainstorm"
# idea_id は省略可（アイデアなしのブレスト部屋）
# → レスポンスに room_code（12文字）と passcode（6文字）が含まれる
```

**リクエスト例（入室）**:
```bash
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"passcode":"AB12CD"}' \
  http://localhost:2300/api/meetings/<room_code>/join
```

**Idea / AI チャット / `/api/me` / 会議 は Bearer token で保護されています。**

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
│   │   ├── ai_chat/              #   AiChatSession / AiChatMessage
│   │   ├── meeting/              #   Meeting（purpose / passcode / status）
│   │   └── meeting_participant/  #   MeetingParticipant
│   ├── jwt_auth.rb               # JWT（Base64URL + HMAC-SHA256）
│   ├── action_auth.rb            # API アクション共通の認証モジュール（authenticate / error_status）
│   ├── gemini_client.rb          # Gemini API クライアント
│   ├── meeting_serializer.rb     # Meeting → JSON ヘルパー
│   ├── websocket_handler.rb      # WS ハンドラ（認証・接続レジストリ）
│   ├── ws_broadcaster.rb         # 配信戦略（LocalBroadcaster / RedisBroadcaster）
│   └── uuid7.rb                  # UUIDv7 生成（RFC 9562）
├── app/
│   ├── usecases/                 # アプリケーション層（操作）
│   │   └── meeting/              #   CreateMeeting / JoinMeeting
│   ├── repos/                    # インフラ層（Sequel 実装・uuid 生成）
│   └── actions/api/
│       ├── accounts/             # 登録 / ログイン
│       ├── me/                   # GET /api/me
│       ├── ideas/                # Idea CRUD（所有権チェック）
│       ├── ai_chat/              # AI 壁打ち
│       ├── messages/             # グローバルチャット（REST）
│       └── meetings/             # 会議 CRUD + join + messages（会議チャット履歴）
├── cable.ru                      # Falcon WS 専用プロセスの entrypoint（:3001）
├── config.ru                     # Hanami HTTP API の entrypoint（:2300）
├── Procfile.dev                  # web / ws / assets の 3 プロセス定義
├── config/{app.rb,routes.rb,db/migrate/}
├── Dockerfile
└── docker-compose.yml            # app / ws / client / db を一括管理
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

### ActionAuth（全 API アクション共通）

認証が必要な API アクションは全て `lib/hanami_auth_app/action_auth.rb` の `ActionAuth` モジュールを include し、

```ruby
account = authenticate(request, response)
return unless account
```

の 2 行で認証する。`authenticate` は Bearer トークンを検証し、role 込みの **Account エンティティ**を返す（失敗時は response を 401 にして nil）。Usecase のエラー文字列 → HTTP ステータスの変換ヘルパー `error_status` も同モジュールが提供する。

## 開発フロー

```bash
docker compose up -d          # 全サービス起動（app / ws / client / db）
docker compose logs -f app    # Hanami API ログ
docker compose logs -f ws     # Falcon WS ログ
docker compose logs -f client # Next.js ログ
docker compose restart app    # Hanami 再起動（変更反映）
docker compose restart ws     # Falcon 再起動
docker compose down           # 停止
```

## 次のステップ

- [x] 会議（meetings）テーブルと参加者（パスコード入室）
- [x] 会議部屋にルームコード（12文字英数字）を導入（UUID より短く共有しやすい）
- [x] WebSocket の会議スコープ化（room_code 単位の接続レジストリ・messages に meeting_id カラム追加）
- [x] 会議内の機能ロール（タイムキーパー / 進行 / 書記 / 発表）
- [x] 認証処理の共通化（全 API アクションを ActionAuth モジュールに統一）
- [x] WS 複数プロセス対応（Redis pub/sub によるブロードキャスト・Falcon --count 2・Sequel fiber_concurrency）
- [x] アイデア検索・フィルタ（`GET /api/ideas?q=&sort=&order=`・ILIKE 部分一致・ソート列ホワイトリスト）
- [ ] ユニット / 統合テストの拡充
- [ ] AWS ECS/Fargate へのデプロイ（Terraform・deploy.yml の有効化）

## 参考

- [ARCHITECTURE.md](ARCHITECTURE.md) — DDD Lite 設計ガイド
- [Hanami ガイド](https://guides.hanamirb.org/)
- [JWT 仕様](https://tools.ietf.org/html/rfc7519)
- [UUIDv7 (RFC 9562)](https://www.rfc-editor.org/rfc/rfc9562)
