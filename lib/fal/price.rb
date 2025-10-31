# frozen_string_literal: true

module Fal
  # Represents pricing information for a model endpoint.
  # Fetches data from the Platform API at /models and /models/pricing.
  class Price
    MODELS_PATH = "/models"
    PRICING_PATH = "/models/pricing"

    # Billing units returned by the pricing service.
    module Unit
      # Output-based units
      IMAGES = "image"
      VIDEOS = "video"
      MEGAPIXELS = "megapixels"

      # Compute-based units (provider-specific)
      GPU_SECONDS = "gpu_second"
      GPU_MINUTES = "gpu_minute"
      GPU_HOURS = "gpu_hour"
    end

    # @return [String]
    attr_reader :endpoint_id
    # @return [Float]
    attr_reader :unit_price
    # @return [String]
    attr_reader :unit
    # @return [String]
    attr_reader :currency

    # @param attributes [Hash] Raw attributes from pricing API
    # @param client [Fal::Client]
    def initialize(attributes, client: Fal.client)
      @client = client
      reset_attributes(attributes)
    end

    class << self
      # Find pricing for a specific model endpoint.
      # @param endpoint_id [String]
      # @param client [Fal::Client]
      # @return [Fal::Price, nil]
      def find_by(endpoint_id:, client: Fal.client)
        response = client.get_api(PRICING_PATH, query: { endpoint_id: endpoint_id })
        entry = Array(response && response["prices"]).find { |p| p["endpoint_id"] == endpoint_id }
        entry ? new(entry, client: client) : nil
      end

      # Iterate over all prices by paging through models and fetching pricing in batches.
      # @param client [Fal::Client]
      # @yield [Fal::Price]
      # @return [void]
      def each(client: Fal.client, &block)
        cursor = nil
        loop do
          models_response = client.get_api(MODELS_PATH, query: { limit: 50, cursor: cursor }.compact)
          models = Array(models_response && models_response["models"])
          endpoint_ids = models.map { |m| m["endpoint_id"] }.compact

          if endpoint_ids.any?
            pricing_response = client.get_api(PRICING_PATH, query: { endpoint_id: endpoint_ids })
            Array(pricing_response && pricing_response["prices"]).each do |attributes|
              block.call(new(attributes, client: client))
            end
          end

          cursor = models_response && models_response["next_cursor"]
          break if cursor.nil?
        end
      end

      # Return an array of all prices.
      # @param client [Fal::Client]
      # @return [Array<Fal::Price>]
      def all(client: Fal.client)
        results = []
        each(client: client) { |price| results << price }
        results
      end
    end

    private

    def reset_attributes(attributes)
      @endpoint_id = attributes["endpoint_id"]
      @unit_price = attributes["unit_price"]
      @unit = attributes["unit"]
      @currency = attributes["currency"]
    end
  end
end
