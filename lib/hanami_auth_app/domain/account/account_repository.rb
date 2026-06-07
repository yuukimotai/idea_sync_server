# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Account
      class AccountRepository
        def find_by_id(id)
          raise NotImplementedError
        end

        def find_by_email(email)
          raise NotImplementedError
        end

        def create(email)
          raise NotImplementedError
        end
      end
    end
  end
end
