# frozen_string_literal: true

module Fal
  # Represents a cost estimate response from the Platform API.
  # Computes estimates via POST /models/pricing/estimate.
  class PriceEstimate
    ESTIMATE_PATH = "/models/pricing/estimate"

    # Supported estimate types.
    module EstimateType
      # @return [String]
      HISTORICAL_API_PRICE = "historical_api_price"
      # @return [String]
      UNIT_PRICE = "unit_price"
    end

    # Simple value object for endpoint inputs.
    class Endpoint
      # @return [String]
      attr_reader :endpoint_id
      # @return [Integer, nil]
      attr_reader :call_quantity
      # @return [Float, nil]
      attr_reader :unit_quantity

      # @param endpoint_id [String]
      # @param call_quantity [Integer, nil]
      # @param unit_quantity [Float, nil]
      def initialize(endpoint_id:, call_quantity: nil, unit_quantity: nil)
        @endpoint_id = endpoint_id
        @call_quantity = call_quantity
        @unit_quantity = unit_quantity
      end
    end

    # @return [String]
    attr_reader :estimate_type
    # @return [Float]
    attr_reader :total_cost
    # @return [String]
    attr_reader :currency

    # @param attributes [Hash]
    # @param client [Fal::Client]
    def initialize(attributes, client: Fal.client)
      @client = client
      reset_attributes(attributes)
    end

    class << self
      # Create a new cost estimate.
      # Corresponds to POST https://api.fal.ai/v1/models/pricing/estimate
      # @param estimate_type [String] one of EstimateType constants
      # @param endpoints [Array<Fal::PriceEstimate::Endpoint, Hash>]
      # @param client [Fal::Client]
      # @return [Fal::PriceEstimate]
      def create(estimate_type:, endpoints:, client: Fal.client)
        endpoint_map = {}
        Array(endpoints).each do |ep|
          endpoint = ep.is_a?(Endpoint) ? ep : Endpoint.new(**ep)
          quantity = endpoint.unit_quantity || endpoint.call_quantity

          if estimate_type == EstimateType::UNIT_PRICE
            # Accept either unit_quantity or call_quantity (treated as units) for convenience.
            endpoint_map[endpoint.endpoint_id] = { "unit_quantity" => quantity }
          else
            endpoint_map[endpoint.endpoint_id] = { "call_quantity" => quantity }
          end
        end

        payload = {
          estimate_type: estimate_type,
          endpoints: endpoint_map
        }

        attributes = client.post_api(ESTIMATE_PATH, payload)
        new(attributes, client: client)
      end
    end

    private

    def reset_attributes(attributes)
      @estimate_type = attributes["estimate_type"]
      @total_cost = attributes["total_cost"]
      @currency = attributes["currency"]
    end
  end
end
