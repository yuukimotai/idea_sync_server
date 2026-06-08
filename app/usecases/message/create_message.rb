# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Message
      class CreateMessage
        def initialize(message_repository)
          @message_repository = message_repository
        end

        def call(input)
          body = input[:body].to_s.strip

          return Domain::Result.err("Message cannot be blank") if body.empty?

          message = @message_repository.create(
            account_id: input[:account_id],
            body: body
          )

          Domain::Result.ok(message: message)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
