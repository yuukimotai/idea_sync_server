# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Account
      class Account
        attr_reader :id, :email, :role

        def initialize(id:, email:, role: "user")
          @id = id
          @email = email
          @role = role
        end

        def admin?
          @role == "admin"
        end

        def user?
          @role == "user"
        end

        def ==(other)
          other.is_a?(Account) &&
            other.id == @id &&
            other.email == @email &&
            other.role == @role
        end
      end
    end
  end
end
