# frozen_string_literal: true

require "test_helper"

class PriceIntegrationTest < Minitest::Test
  ENDPOINT_ID = "fal-ai/flux/dev"

  def test_find_by_returns_price
    price = Fal::Price.find_by(endpoint_id: ENDPOINT_ID)
    refute_nil price
    assert_equal ENDPOINT_ID, price.endpoint_id
    refute_nil price.unit
    refute_nil price.currency
    assert_operator price.unit_price, :>=, 0.0
  end
end
