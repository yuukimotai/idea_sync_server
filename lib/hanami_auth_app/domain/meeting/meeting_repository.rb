# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Meeting
      class MeetingRepository
        def create(idea_id:, created_by:, title:)
          raise NotImplementedError
        end

        def find_by_id(id)
          raise NotImplementedError
        end

        def list_all
          raise NotImplementedError
        end

        def list_for_account(account_id)
          raise NotImplementedError
        end

        def update_status(id, status)
          raise NotImplementedError
        end
      end
    end
  end
end
