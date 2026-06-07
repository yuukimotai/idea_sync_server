# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Account
      class Account
        attr_reader :id, :email

        def initialize(id:, email:)
          @id = id
          @email = email
        end

        def ==(other)
          other.is_a?(Account) && other.id == @id && other.email == @email
        end
      end
    end
  end
end
