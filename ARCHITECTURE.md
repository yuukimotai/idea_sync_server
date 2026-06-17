# アーキテクチャ — DDD Lite 実装ガイド

このプロジェクトは **DDD Lite（Domain-Driven Design Lite）** アーキテクチャを採用しています。

## 全体像

```
┌─────────────────────────────────────────────────────┐
│  プレゼンテーション層                                │
│  (app/actions/)                                      │
│  HTTP リクエスト ↔ ユースケース                      │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│  アプリケーション層                                  │
│  (app/usecases/)                                     │
│  ビジネス操作（Create/Read/Update/Delete）           │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│  ドメイン層                                          │
│  (lib/hanami_auth_app/domain/)                      │
│  エンティティ ⊢ ビジネスルール ⊢ ポリシー           │
└────────────────────┬────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│  インフラ層                                          │
│  (app/repos/)                                        │
│  リポジトリ実装（DB CRUD）                            │
└─────────────────────────────────────────────────────┘
```

## レイヤー説明

### 1. ドメイン層 (`lib/hanami_auth_app/domain/`)

**責務**: ビジネスロジックの中核をモデル化

```
domain/
├── shared/
│   └── result.rb           # 成功/失敗を表す値オブジェクト
├── account/
│   ├── account.rb          # Account エンティティ（id, email）
│   └── account_repository.rb # Repository インターフェース（抽象）
└── todo/
    ├── todo.rb             # Todo エンティティ（id, account_id, title, completed）
    ├── todo_repository.rb  # Repository インターフェース（抽象）
    └── （ポリシークラスはここに）
```

**実装パターン**:

```ruby
# todo.rb — エンティティ
class Todo
  attr_reader :id, :account_id, :title, :completed

  def initialize(id:, account_id:, title:, completed: false, ...)
    @id = id
    @account_id = account_id
    # ...
  end

  # ビジネスロジック：外部に依存しない
  def toggle
    Todo.new(
      id: @id,
      completed: !@completed,
      # ...
    )
  end
end

# todo_repository.rb — Repository インターフェース
class TodoRepository
  def create(account_id:, title:)
    raise NotImplementedError
  end
  # 他のメソッド定義
end
```

**特徴**:
- **データベース非依存** — SQL を知らない
- **フレームワーク非依存** — Hanami/Rails どちらでも使える
- **テスト容易** — モックしやすい

---

### 2. アプリケーション層 (`app/usecases/`)

**責務**: ユースケース（操作）の実装、ドメイン層とインフラ層を調整

```
usecases/
└── todo/
    ├── create_todo.rb      # Use Case: Todo 作成
    ├── list_todos.rb       # Use Case: Todo 一覧取得
    ├── update_todo.rb      # Use Case: Todo 更新
    ├── delete_todo.rb      # Use Case: Todo 削除
    └── toggle_todo.rb      # Use Case: Todo 完了トグル
```

**実装パターン**:

```ruby
# app/usecases/todo/create_todo.rb
class CreateTodo < HanamiAuthApp::Operation
  input :account_id, :title
  output :todo

  def call(input)
    # バリデーション
    title = input[:title].to_s.strip
    return Failure(message: "Title cannot be blank") if title.empty?

    # リポジトリで永続化
    todo = container[:todo_repository].create(
      account_id: input[:account_id],
      title: title
    )

    # 結果を返す
    Success(todo: todo)
  rescue => e
    Failure(message: e.message)
  end
end
```

**特徴**:
- `Dry::Operation` ベース（Hanami `Operation` クラス継承）
- **入出力が型チェック** (input/output で定義)
- **失敗パターンを明示** (Success/Failure)
- **テスト可能** — モック Repository を差し替え可

---

### 3. インフラ層 (`app/repos/`)

**責務**: ドメインインターフェースの具体実装

```
repos/
└── todo_repository.rb      # TodoRepository の Sequel 実装
```

**実装パターン**:

```ruby
# app/repos/todo_repository.rb
class TodoRepository < Domain::Todo::TodoRepository
  def initialize(db = nil)
    @db = db || HanamiAuthApp::RODAUTH_DB
  end

  def create(account_id:, title:)
    row = @db[:todos].insert(
      account_id: account_id,
      title: title,
      # ...
    )
    to_entity(row)  # DB 行 → Domain エンティティに変換
  end

  # ドメイン層へのデータ変換
  private

  def to_entity(row)
    Domain::Todo::Todo.new(
      id: row[:id],
      account_id: row[:account_id],
      title: row[:title],
      # ...
    )
  end
end
```

**特徴**:
- **ドメイン Repository インターフェースを実装**
- **DB 行とドメインエンティティ間の変換**（impedance mismatch 回避）
- **DB の詳細（Sequel）を隠蔽**

---

### 4. プレゼンテーション層 (`app/actions/`)

**責務**: HTTP リクエスト ↔ ユースケース ↔ HTTP レスポンス

```
actions/
├── home/
│   └── index.rb            # GET /
└── todo/
    ├── index.rb            # GET /todos
    └── create.rb           # GET /todos/new, POST /todos
```

**実装パターン**:

```ruby
# app/actions/todo/index.rb
class Index < HanamiAuthApp::Action
  include Hanami::Action::Session

  def handle(request, response)
    # HTTP 層：セッションから account_id を抽出
    account_id = request.env["rack.session"]&.[](:account_id)
    return response.redirect "/login" unless account_id

    # ビジネス層：ユースケース呼び出し
    usecase = Usecases::Todo::ListTodos.new(container: container)
    result = usecase.call(account_id: account_id)

    # プレゼンテーション層：結果をビューに変換
    if result.success?
      response.body = render_todos(request, result[:todos])
    else
      response.status = 500
    end
  end
end
```

**特徴**:
- **HTTP リクエスト/レスポンス処理のみ**
- **ビジネスロジックなし** ← ユースケースに委譲
- **エラーハンドリング** — ユースケース結果を HTTP ステータスに変換

---

## 認証・認可の位置付け

認証は **JWT Bearer token**（`lib/hanami_auth_app/jwt_auth.rb`、Base64URL + HMAC-SHA256 の手動実装）で行う。各 API Action がリクエストの `Authorization` ヘッダからトークンを検証する。

```
リクエスト
  ├ Authorization: Bearer <token>
  ↓
[Action] JwtAuth.decode(token) → payload["account_id"]（UUIDv7）
  ↓
[Usecase] account_id を受け取り、所有権を判定
```

**ポイント**:
- Actions はトークンを検証して `account_id` を取り出す（セッションは使わない）。
- **ロール**（`user` / `admin`）はトークンに焼き込まず、`GET /api/me` などで都度 DB から取得する（昇格/降格を即反映するため）。
- **所有権チェック**は Usecase 層で行う（例: `idea.account_id == account_id` でなければ `Forbidden`）。ドメインは認証の詳細を知らず、account_id で判定するだけ。

> 注: 旧構成では Rodauth + セッションを検討していたが、API ファースト化に伴い JWT Bearer に統一した。

---

## Todo CRUD パターンの実装フロー

### 1. ユーザーが "新規 Todo" をクリック

```
GET /todos/new
  ↓
[Action::Todo::Create#handle (GET)]
  ↓ render form
[HTML: <form method="post" action="/todos">]
```

### 2. ユーザーが Title を入力し送信

```
POST /todos
  ↓
[Action::Todo::Create#handle (POST)]
  ├ セッションから account_id 取得
  ├ request.params[:title] を抽出
  ↓
[Usecase::Todo::CreateTodo#call]
  ├ バリデーション（title は空でないか）
  ├ リポジトリで DB に保存
  ├ Result::Success(todo: ...) を返す
  ↓
[Action::Todo::Create#handle (結果処理)]
  ├ result.success? → /todos にリダイレクト
  └ result.failure? → 400 + エラーメッセージ
```

### 3. ユーザーが /todos を訪問

```
GET /todos
  ↓
[Action::Todo::Index#handle]
  ├ セッションから account_id 取得
  ↓
[Usecase::Todo::ListTodos#call(account_id: ...)]
  ├ リポジトリから todos を取得
  ├ Result::Success(todos: [...]) を返す
  ↓
[Action::Todo::Index#render_todos]
  ├ Todo エンティティを HTML テーブルに変換
  ↓
[HTTP 200: HTML]
```

---

## DI コンテナ（Dependency Injection）

### 設定 (`config/app.rb`)

```ruby
module HanamiAuthApp
  class App < Hanami::App
    # リポジトリをコンテナに登録
    register :todo_repository, HanamiAuthApp::Repos::TodoRepository.new
  end
end
```

### 利用 (Action/Usecase)

```ruby
# Action から container を通じてリポジトリにアクセス
usecase = Usecases::Todo::ListTodos.new(container: container)
result = usecase.call(account_id: account_id)

# Usecase 内
def call(input)
  todos = container[:todo_repository].list_by_account(input[:account_id])
  # ...
end
```

**メリット**:
- テスト時にモック Repository に差し替え可能
- 依存関係が明示的

---

## テスト戦略

### ユニットテスト（ドメイン層）

```ruby
describe Domain::Todo::Todo do
  it "toggles completed status" do
    todo = Todo.new(id: 1, completed: false, ...)
    toggled = todo.toggle

    expect(toggled.completed).to be true
  end
end
```

### インテグレーションテスト（ユースケース）

```ruby
describe Usecases::Todo::CreateTodo do
  it "creates a todo with valid title" do
    repo = TodoRepository.new  # 実 DB
    usecase = CreateTodo.new(container: { todo_repository: repo })
    result = usecase.call(account_id: 1, title: "Test")

    expect(result.success?).to be true
    expect(result[:todo].title).to eq "Test"
  end
end
```

### E2E テスト（HTTP）

```ruby
# Rack テスト
get "/todos"
expect(last_response.status).to eq 200
expect(last_response.body).to include "My Todos"
```

---

## 今後の拡張方針

### 1. API モード対応
- Usecase はそのまま → JSON レスポンスに変更

```ruby
# app/actions/api/todo/index.rb
class HanamiAuthApp::Actions::Api::Todo::Index
  def handle(request, response)
    # ...
    response.format = :json
    response.body = result[:todos].map { |t| { id: t.id, title: t.title, ... } }.to_json
  end
end
```

### 2. 複雑なビジネスルール追加
- ドメイン層にポリシークラスを追加

```ruby
# lib/hanami_auth_app/domain/todo/todo_list_policy.rb
class TodoListPolicy
  def can_assign?(account_id, todo)
    todo.account_id == account_id  # 他人のタスクは操作不可
  end
end
```

### 3. イベントソーシング
- Usecase から Domain Events を発行

```ruby
def call(input)
  todo = ...
  events.publish(TodoCreated.new(todo: todo))
  Success(todo: todo)
end
```

---

## 参考資料

- **DDD**: Evans, "Domain-Driven Design"
- **Hanami**: https://guides.hanamirb.org/
- **Dry::Operation**: https://dry-rb.org/gems/dry-operation/
- **Repository パターン**: https://martinfowler.com/eaaCatalog/repository.html
