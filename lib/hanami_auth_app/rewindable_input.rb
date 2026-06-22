# frozen_string_literal: true

require "stringio"

module HanamiAuthApp
  # Falcon など rack.input が「非巻き戻し(streaming)」なサーバーでも、
  # アクション内の `request.body.read` が確実に本文を読めるよう、
  # リクエストボディを一度だけ読んで StringIO（巻き戻し可）に差し替えるミドルウェア。
  #
  # Puma の rack.input は巻き戻し可だったため問題にならなかったが、
  # Falcon ではこれが無いと POST/PATCH の JSON ボディが空になる。
  class RewindableInput
    def initialize(app)
      @app = app
    end

    def call(env)
      input = env["rack.input"]
      if input
        body = input.read
        env["rack.input"] = StringIO.new(body.to_s)
      end
      @app.call(env)
    end
  end
end
