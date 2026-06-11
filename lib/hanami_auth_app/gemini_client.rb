# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module HanamiAuthApp
  class GeminiClient
    MODEL = "gemini-3.1-flash-lite"
    API_BASE = "https://generativelanguage.googleapis.com/v1beta/models"

    def initialize(api_key = nil)
      @api_key = api_key || ENV.fetch("GEMINI_API_KEY")
    end

    def chat(messages:, system_prompt: nil)
      uri = URI("#{API_BASE}/#{MODEL}:generateContent?key=#{@api_key}")

      contents = messages.map do |msg|
        {
          role: msg[:role],
          parts: [{ text: msg[:body] }]
        }
      end

      body = { contents: contents }
      if system_prompt
        body[:system_instruction] = { parts: [{ text: system_prompt }] }
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = body.to_json

      response = http.request(request)
      parsed = JSON.parse(response.body)

      if response.code.to_i != 200
        raise "Gemini API error: #{parsed.dig("error", "message") || response.body}"
      end

      parsed.dig("candidates", 0, "content", "parts", 0, "text")
    end
  end
end
