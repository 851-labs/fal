# frozen_string_literal: true

require "test_helper"

class PriceEstimateIntegrationTest < Minitest::Test
  ENDPOINT_ID = "fal-ai/flux/dev"

  def test_unit_price_estimate
    estimate = Fal::PriceEstimate.create(
      estimate_type: Fal::PriceEstimate::EstimateType::UNIT_PRICE,
      endpoints: [Fal::PriceEstimate::Endpoint.new(endpoint_id: ENDPOINT_ID, unit_quantity: 1)]
    )

    assert_equal Fal::PriceEstimate::EstimateType::UNIT_PRICE, estimate.estimate_type
    assert_operator estimate.total_cost, :>=, 0.0
    refute_nil estimate.currency
  end

  def test_historical_api_price_estimate
    estimate = Fal::PriceEstimate.create(
      estimate_type: Fal::PriceEstimate::EstimateType::HISTORICAL_API_PRICE,
      endpoints: [Fal::PriceEstimate::Endpoint.new(endpoint_id: ENDPOINT_ID, call_quantity: 1)]
    )

    assert_equal Fal::PriceEstimate::EstimateType::HISTORICAL_API_PRICE, estimate.estimate_type
    assert_operator estimate.total_cost, :>=, 0.0
    refute_nil estimate.currency
  end
end
