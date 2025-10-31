# frozen_string_literal: true

require "test_helper"

class ModelIntegrationTest < Minitest::Test
  ENDPOINT_ID = "fal-ai/flux/dev"

  def test_find_by_fetches_model_from_api
    model = Fal::Model.find_by(endpoint_id: ENDPOINT_ID)
    refute_nil model
    assert_equal ENDPOINT_ID, model.endpoint_id
  end
end
