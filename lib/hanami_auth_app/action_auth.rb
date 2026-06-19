# frozen_string_literal: true

require_relative "jwt_auth"

module HanamiAuthApp
  # API アクション共通の認証ヘルパー。
  # Bearer トークンを検証し、role 込みの Account エンティティを返す。
  # 認証に失敗した場合は response を 401 にして nil を返す。
  module ActionAuth
    def authenticate(request, response)
      auth_header = request.env["HTTP_AUTHORIZATION"]
      unless auth_header&.start_with?("Bearer ")
        render_error(response, 401, "Missing or invalid authorization header")
        return nil
      end

      payload = JwtAuth.decode(auth_header.sub("Bearer ", ""))
      unless payload
        render_error(response, 401, "Invalid token")
        return nil
      end

      account = HanamiAuthApp::App.container.resolve(:account_repository)
        .find_by_id(payload["account_id"])
      unless account
        render_error(response, 401, "Account not found")
        return nil
      end

      account
    end

    def render_error(response, status, message)
      response.status = status
      response.body = { error: message }.to_json
    end

    # Usecase が返すエラー文字列を HTTP ステータスに対応づける。
    def error_status(error)
      case error
      when "Forbidden" then 403
      when /not found\z/ then 404
      else 400
      end
    end
  end
end
