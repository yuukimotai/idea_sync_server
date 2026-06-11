# frozen_string_literal: true

require_relative "../../../lib/hanami_auth_app/gemini_client"

module HanamiAuthApp
  module Usecases
    module AiChat
      class SendMessage
        def initialize(session_repository, message_repository, idea_repository, gemini_client = nil)
          @session_repository = session_repository
          @message_repository = message_repository
          @idea_repository = idea_repository
          @gemini_client = gemini_client || GeminiClient.new
        end

        def call(account_id:, session_id:, body:)
          body = body.to_s.strip
          return Domain::Result.err("Message cannot be blank") if body.empty?

          session = @session_repository.find_by_id(session_id)
          return Domain::Result.err("Session not found") unless session
          return Domain::Result.err("Forbidden") unless session.account_id == account_id

          idea = @idea_repository.find_by_id(session.idea_id)
          return Domain::Result.err("Idea not found") unless idea

          user_message = @message_repository.create(
            session_id: session_id,
            role: "user",
            body: body
          )

          history = @message_repository.list_by_session(session_id: session_id)
          gemini_messages = history.map { |m| { role: m.role == "model" ? "model" : "user", body: m.body } }

          system_prompt = build_system_prompt(idea)
          reply_text = @gemini_client.chat(messages: gemini_messages, system_prompt: system_prompt)

          ai_message = @message_repository.create(
            session_id: session_id,
            role: "model",
            body: reply_text
          )

          Domain::Result.ok(user_message: user_message, ai_message: ai_message)
        rescue => e
          Domain::Result.err(e.message)
        end

        private

        def build_system_prompt(idea)
          <<~PROMPT
            あなたはアイデアの壁打ち相手です。ユーザーのアイデアについて、建設的なフィードバックや質問、改善案を提供してください。

            対象アイデア:
            タイトル: #{idea.title}
            説明: #{idea.description}

            このアイデアを中心に会話を進めてください。批判的になりすぎず、ユーザーの思考を深める手助けをしてください。
          PROMPT
        end
      end
    end
  end
end
