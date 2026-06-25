# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Meeting
      class MeetingRepository
        def create(created_by:, title:, purpose:, idea_id: nil)
          raise NotImplementedError
        end

        def find_by_id_and_passcode(id, passcode)
          raise NotImplementedError
        end

        def find_by_room_code(room_code)
          raise NotImplementedError
        end

        def find_by_room_code_and_passcode(room_code, passcode)
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
