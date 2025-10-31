# frozen_string_literal: true

require "test_helper"

class PriceEstimateTest < Minitest::Test
  class FakeClient
    def initialize(stubs: {})
      @stubs = stubs
      @configuration = Fal::Configuration.new
    end

    def post_api(path, payload = nil, headers: {})
      call(:post_api, path, payload, headers)
    end

    private

    def call(method, path_or_key, payload, headers)
      key = [method, path_or_key]
      responder = @stubs[key]
      raise "No stub for #{key.inspect}" unless responder

      if responder.respond_to?(:call)
        responder.call(payload, headers)
      else
        responder
      end
    end
  end

  def test_unit_price_estimate_accepts_call_quantity_alias
    path = "/models/pricing/estimate"

    expected_payload = {
      estimate_type: Fal::PriceEstimate::EstimateType::UNIT_PRICE,
      endpoints: {
        "fal-ai/flux/dev" => { "unit_quantity" => 50 },
        "fal-ai/flux-pro" => { "unit_quantity" => 25 }
      }
    }

    response_body = {
      "estimate_type" => "unit_price",
      "total_cost" => 1.88,
      "currency" => "USD"
    }

    stubs = {
      [:post_api, path] => lambda do |payload, _headers|
        # Ensure call_quantity was mapped to unit_quantity for UNIT_PRICE
        raise "payload mismatch: #{payload.inspect}" unless payload == expected_payload

        response_body
      end
    }

    client = FakeClient.new(stubs: stubs)

    estimate = Fal::PriceEstimate.create(
      estimate_type: Fal::PriceEstimate::EstimateType::UNIT_PRICE,
      endpoints: [
        Fal::PriceEstimate::Endpoint.new(endpoint_id: "fal-ai/flux/dev", call_quantity: 50),
        Fal::PriceEstimate::Endpoint.new(endpoint_id: "fal-ai/flux-pro", unit_quantity: 25)
      ],
      client: client
    )

    assert_equal "unit_price", estimate.estimate_type
    assert_in_delta 1.88, estimate.total_cost, 0.00001
    assert_equal "USD", estimate.currency
  end

  def test_historical_api_price_estimate_uses_call_quantity
    path = "/models/pricing/estimate"

    expected_payload = {
      estimate_type: Fal::PriceEstimate::EstimateType::HISTORICAL_API_PRICE,
      endpoints: {
        "fal-ai/flux/dev" => { "call_quantity" => 100 }
      }
    }

    response_body = {
      "estimate_type" => "historical_api_price",
      "total_cost" => 3.75,
      "currency" => "USD"
    }

    stubs = {
      [:post_api, path] => lambda do |payload, _headers|
        raise "payload mismatch: #{payload.inspect}" unless payload == expected_payload

        response_body
      end
    }

    client = FakeClient.new(stubs: stubs)

    estimate = Fal::PriceEstimate.create(
      estimate_type: Fal::PriceEstimate::EstimateType::HISTORICAL_API_PRICE,
      endpoints: [
        Fal::PriceEstimate::Endpoint.new(endpoint_id: "fal-ai/flux/dev", call_quantity: 100)
      ],
      client: client
    )

    assert_equal "historical_api_price", estimate.estimate_type
    assert_in_delta 3.75, estimate.total_cost, 0.00001
    assert_equal "USD", estimate.currency
  end
end
