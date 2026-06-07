# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Idea
      class Idea
        attr_reader :id, :account_id, :title, :description, :created_at, :updated_at

        def initialize(id:, account_id:, title:, description: "", created_at: nil, updated_at: nil)
          @id = id
          @account_id = account_id
          @title = title
          @description = description
          @created_at = created_at
          @updated_at = updated_at
        end

        def update_title(new_title)
          Idea.new(
            id: @id,
            account_id: @account_id,
            title: new_title,
            description: @description,
            created_at: @created_at,
            updated_at: Time.now
          )
        end

        def update_description(new_description)
          Idea.new(
            id: @id,
            account_id: @account_id,
            title: @title,
            description: new_description,
            created_at: @created_at,
            updated_at: Time.now
          )
        end

        def ==(other)
          other.is_a?(Idea) && other.id == @id
        end
      end
    end
  end
end
