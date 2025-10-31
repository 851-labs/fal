# frozen_string_literal: true

require "test_helper"

class StreamIntegrationTest < Minitest::Test
  ENDPOINT_ID = "fal-ai/flux/dev"

  def test_stream_yields_events_and_returns_completed_request
    yielded = []
    request = Fal::Request.stream!(endpoint_id: ENDPOINT_ID, input: { prompt: "stream a cat" }) do |chunk|
      yielded << chunk
    end

    refute_empty yielded
    # Some final chunks may not include status; accept either a COMPLETED status at any point
    # or a non-nil response on the returned request.
    completed_in_stream = yielded.any? { |chunk| chunk["status"] == Fal::Request::Status::COMPLETED }
    assert completed_in_stream || !request.response.nil?
    refute_nil request.response
  end
end
