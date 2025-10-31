# frozen_string_literal: true

require "test_helper"

class RequestTest < Minitest::Test
  class FakeClient
    def initialize(stubs: {})
      @stubs = stubs
      @configuration = Fal::Configuration.new
    end

    def post(path, payload = {}, headers: {})
      call(:post, path, payload, headers)
    end

    def get(path, query: nil, headers: {})
      key = query && !query.empty? ? [path, query] : [path]
      call(:get, key, nil, headers)
    end

    def put(path)
      call(:put, path, {}, {})
    end

    private

    def call(method, path_or_key, payload, headers)
      key = case method
            when :get then [:get, *Array(path_or_key)]
            else [method, path_or_key]
            end
      responder = @stubs[key]
      raise "No stub for #{key.inspect}" unless responder

      if responder.respond_to?(:call)
        responder.call(payload, headers)
      else
        responder
      end
    end
  end

  def test_submit_and_status_and_cancel
    endpoint_id = "fal-ai/fast-sdxl"
    request_id = "req-123"

    stubs = {
      [:post, "/#{endpoint_id}"] => {
        "request_id" => request_id,
        "response_url" => "https://queue.fal.run/#{endpoint_id}/requests/#{request_id}",
        "status_url" => "https://queue.fal.run/#{endpoint_id}/requests/#{request_id}/status",
        "cancel_url" => "https://queue.fal.run/#{endpoint_id}/requests/#{request_id}/cancel"
      },
      [:get, "/#{endpoint_id}/requests/#{request_id}/status"] => {
        "status" => "IN_QUEUE",
        "queue_position" => 0,
        "response_url" => "https://queue.fal.run/#{endpoint_id}/requests/#{request_id}"
      },
      [:get, "/#{endpoint_id}/requests/#{request_id}/status", { logs: 1 }] => {
        "status" => "IN_PROGRESS",
        "logs" => [{ "message" => "processing" }],
        "response_url" => "https://queue.fal.run/#{endpoint_id}/requests/#{request_id}"
      },
      [:put, "/#{endpoint_id}/requests/#{request_id}/cancel"] => { "status" => "CANCELLATION_REQUESTED" }
    }

    client = FakeClient.new(stubs: stubs)

    request = Fal::Request.create!(endpoint_id: endpoint_id, input: { prompt: "a cat" }, client: client)
    assert_equal request_id, request.id
    assert request.in_queue?

    request.reload!
    assert request.in_queue?

    request.reload!(logs: true)
    assert request.in_progress?
    refute_nil request.logs

    response = request.cancel!
    assert_equal({ "status" => "CANCELLATION_REQUESTED" }, response)
  end
end
