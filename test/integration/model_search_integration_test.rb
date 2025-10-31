# frozen_string_literal: true

require "test_helper"

class ModelSearchIntegrationTest < Minitest::Test
  def test_each_and_all_returns_models
    collected = []
    count = 0
    Fal::Model.each do |m|
      collected << m.endpoint_id
      count += 1
      break if count >= 5
    end
    refute_empty collected
  end
end
