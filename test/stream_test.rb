# frozen_string_literal: true

require "test_helper"

class StreamTest < Minitest::Test
  class FakeClient
    def initialize(chunks: [])
      @chunks = chunks
      @configuration = Fal::Configuration.new
    end

    def post_stream(_path, _payload = {}, on_data:)
      # simulate calling on_data with provided chunks
      @chunks.each do |chunk|
        on_data.call(chunk, chunk.bytesize)
      end
    end
  end

  def test_stream_yields_chunks_and_returns_request_with_last_chunk
    endpoint_id = "fal-ai/flux/dev"

    # Build SSE-style stream: data lines followed by blank line between events
    event1 = "data: {\"status\": \"IN_PROGRESS\", \"progress\": 0.1}\n\n"
    event2 = "data: {\"status\": \"IN_PROGRESS\", \"progress\": 0.5}\n\n"
    event3 = "data: {\"status\": \"COMPLETED\", \"response\": {\"image\": \"url\"}}\n\n"

    client = FakeClient.new(chunks: [event1, event2, event3])

    yielded = []
    request = Fal::Request.stream!(endpoint_id: endpoint_id, input: { prompt: "hi" }, client: client) do |chunk|
      yielded << chunk
    end

    assert_equal 3, yielded.size
    assert_equal "IN_PROGRESS", yielded[0]["status"]
    assert_equal 0.5, yielded[1]["progress"]
    assert_equal "COMPLETED", yielded.last["status"]

    # The returned request should have last chunk as response
    assert request.completed?
    assert_equal({ "image" => "url" }, request.response)
  end
end
