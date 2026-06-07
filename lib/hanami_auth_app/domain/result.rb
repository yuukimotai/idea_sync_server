# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    class Result
      attr_reader :value, :error

      def initialize(value: nil, error: nil)
        @value = value
        @error = error
      end

      def success?
        @error.nil?
      end

      def failure?
        !success?
      end

      def self.ok(value)
        new(value: value)
      end

      def self.err(error)
        new(error: error)
      end

      def map
        success? ? yield(value) : self
      end

      def flat_map
        success? ? yield(value) : self
      end
    end
  end
end
