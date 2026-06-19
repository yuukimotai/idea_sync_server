# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Meeting
      class Meeting
        STATUSES = %w[draft active closed].freeze

        attr_reader :id, :idea_id, :created_by, :title, :status, :created_at, :updated_at

        def initialize(id:, idea_id:, created_by:, title:, status: "draft", created_at: nil, updated_at: nil)
          @id = id
          @idea_id = idea_id
          @created_by = created_by
          @title = title
          @status = status
          @created_at = created_at
          @updated_at = updated_at
        end

        def ==(other)
          other.is_a?(Meeting) && other.id == @id
        end
      end
    end
  end
end
