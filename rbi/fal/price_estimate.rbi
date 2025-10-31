# typed: strict
# frozen_string_literal: true

module Fal
  class PriceEstimate
    ESTIMATE_PATH = T.let(T.unsafe(nil), String)

    module EstimateType
      HISTORICAL_API_PRICE = T.let(T.unsafe(nil), String)
      UNIT_PRICE = T.let(T.unsafe(nil), String)
    end

    class Endpoint
      sig { returns(String) }
      def endpoint_id; end

      sig { returns(T.nilable(Integer)) }
      def call_quantity; end

      sig { returns(T.nilable(Float)) }
      def unit_quantity; end

      sig do
        params(
          endpoint_id: String,
          call_quantity: T.nilable(Integer),
          unit_quantity: T.nilable(Float)
        ).void
      end
      def initialize(endpoint_id:, call_quantity: nil, unit_quantity: nil); end
    end

    sig { returns(String) }
    def estimate_type; end

    sig { returns(Float) }
    def total_cost; end

    sig { returns(String) }
    def currency; end

    sig { params(attributes: T.untyped, client: Fal::Client).void }
    def initialize(attributes, client: Fal.client); end

    class << self
      sig do
        params(
          estimate_type: String,
          endpoints: T::Array[T.any(Fal::PriceEstimate::Endpoint, T.untyped)],
          client: Fal::Client
        ).returns(Fal::PriceEstimate)
      end
      def create(estimate_type:, endpoints:, client: Fal.client); end
    end

    private

    sig { params(attributes: T.untyped).void }
    def reset_attributes(attributes); end
  end
end
