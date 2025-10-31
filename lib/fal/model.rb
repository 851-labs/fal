# frozen_string_literal: true

module Fal
  # Represents a model endpoint discoverable via the Models API.
  # Provides helpers to list, search, and fetch pricing and to run requests.
  class Model
    MODELS_PATH = "/models"

    # @return [String]
    attr_reader :endpoint_id
    # Flattened metadata fields
    # @return [String, nil]
    attr_reader :display_name
    # @return [String, nil]
    attr_reader :category
    # @return [String, nil]
    attr_reader :description
    # @return [String, nil]
    attr_reader :status
    # @return [Array<String>, nil]
    attr_reader :tags
    # @return [String, nil]
    attr_reader :updated_at
    # @return [Boolean, nil]
    attr_reader :is_favorited
    # @return [String, nil]
    attr_reader :thumbnail_url
    # @return [String, nil]
    attr_reader :thumbnail_animated_url
    # @return [String, nil]
    attr_reader :model_url
    # @return [String, nil]
    attr_reader :github_url
    # @return [String, nil]
    attr_reader :license_type
    # @return [String, nil]
    attr_reader :date
    # @return [Hash, nil]
    attr_reader :group
    # @return [Boolean, nil]
    attr_reader :highlighted
    # @return [String, nil]
    attr_reader :kind
    # @return [Array<String>, nil]
    attr_reader :training_endpoint_ids
    # @return [Array<String>, nil]
    attr_reader :inference_endpoint_ids
    # @return [String, nil]
    attr_reader :stream_url
    # @return [Float, nil]
    attr_reader :duration_estimate
    # @return [Boolean, nil]
    attr_reader :pinned
    # @return [Hash, nil]
    attr_reader :openapi

    # @param attributes [Hash]
    # @param client [Fal::Client]
    def initialize(attributes, client: Fal.client)
      @client = client
      reset_attributes(attributes)
    end

    # Fetch and memoize the price object for this model's endpoint.
    # @return [Fal::Price, nil]
    def price
      @price ||= Fal::Price.find_by(endpoint_id: @endpoint_id, client: @client)
    end

    # Run a queued request for this model endpoint.
    # @param input [Hash]
    # @param webhook_url [String, nil]
    # @return [Fal::Request]
    def run(input:, webhook_url: nil)
      Fal::Request.create!(endpoint_id: @endpoint_id, input: input, webhook_url: webhook_url, client: @client)
    end

    class << self
      # Find a specific model by endpoint_id.
      # @param endpoint_id [String]
      # @param client [Fal::Client]
      # @return [Fal::Model, nil]
      def find_by(endpoint_id:, client: Fal.client)
        response = client.get_api(MODELS_PATH, query: { endpoint_id: endpoint_id })
        entry = Array(response && response["models"]).find { |m| m["endpoint_id"] == endpoint_id }
        entry ? new(entry, client: client) : nil
      end

      # Iterate through models with optional search filters.
      # @param client [Fal::Client]
      # @param query [String, nil] Free-text search query
      # @param category [String, nil]
      # @param status [String, nil]
      # @param expand [Array<String>, String, nil]
      # @yield [Fal::Model]
      # @return [void]
      def each(client: Fal.client, query: nil, category: nil, status: nil, expand: nil, &block)
        cursor = nil
        loop do
          query_hash = { limit: 50, cursor: cursor, q: query, category: category, status: status }.compact
          query_hash[:expand] = expand if expand
          response = client.get_api(MODELS_PATH, query: query_hash)
          models = Array(response && response["models"])
          models.each { |attributes| block.call(new(attributes, client: client)) }
          cursor = response && response["next_cursor"]
          break if cursor.nil?
        end
      end

      # Return an array of models for the given filters (or all models).
      # @param client [Fal::Client]
      # @param query [String, nil]
      # @param category [String, nil]
      # @param status [String, nil]
      # @param expand [Array<String>, String, nil]
      # @return [Array<Fal::Model>]
      def all(client: Fal.client, query: nil, category: nil, status: nil, expand: nil)
        results = []
        each(client: client, query: query, category: category, status: status, expand: expand) { |m| results << m }
        results
      end

      # Convenience search wrapper that returns all matching models.
      # @param client [Fal::Client]
      # @param query [String, nil]
      # @param category [String, nil]
      # @param status [String, nil]
      # @param expand [Array<String>, String, nil]
      # @return [Array<Fal::Model>]
      def search(query: nil, category: nil, status: nil, expand: nil, client: Fal.client)
        all(client: client, query: query, category: category, status: status, expand: expand)
      end
    end

    private

    def reset_attributes(attributes)
      @endpoint_id = attributes["endpoint_id"]

      meta = attributes["metadata"] || {}
      @display_name = meta["display_name"]
      @category = meta["category"]
      @description = meta["description"]
      @status = meta["status"]
      @tags = meta["tags"]
      @updated_at = meta["updated_at"]
      @is_favorited = meta["is_favorited"]
      @thumbnail_url = meta["thumbnail_url"]
      @thumbnail_animated_url = meta["thumbnail_animated_url"]
      @model_url = meta["model_url"]
      @github_url = meta["github_url"]
      @license_type = meta["license_type"]
      @date = meta["date"]
      @group = meta["group"]
      @highlighted = meta["highlighted"]
      @kind = meta["kind"]
      @training_endpoint_ids = meta["training_endpoint_ids"]
      @inference_endpoint_ids = meta["inference_endpoint_ids"]
      @stream_url = meta["stream_url"]
      @duration_estimate = meta["duration_estimate"]
      @pinned = meta["pinned"]

      @openapi = attributes["openapi"]
    end
  end
end
