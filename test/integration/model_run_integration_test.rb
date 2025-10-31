# frozen_string_literal: true

require "test_helper"

class ModelRunIntegrationTest < Minitest::Test
  ENDPOINT_ID = "fal-ai/flux/dev"

  def test_model_instance_run_creates_request
    model = Fal::Model.find_by(endpoint_id: ENDPOINT_ID)
    refute_nil model

    request = model.run(input: { prompt: "instance run" })
    assert_kind_of Fal::Request, request
    refute_nil request.id
  end
end
