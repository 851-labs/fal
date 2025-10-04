# frozen_string_literal: true

require "test_helper"

class WebhookRequestTest < Minitest::Test
  def test_from_json_success
    json = {
      status: "OK",
      request_id: "abc",
      gateway_request_id: "gw-1",
      payload: { message: "done" },
      logs: [{ message: "log" }],
      metrics: { t: 1.2 }
    }.to_json

    wr = Fal::WebhookRequest.from_json(json)
    assert wr.success?
    assert_equal "abc", wr.request_id
    assert_equal({ message: "done" }, wr.response)
    assert_equal [{ message: "log" }], wr.logs
  end

  def test_from_hash_error
    payload = {
      status: "ERROR",
      request_id: "abc",
      error: "boom",
      payload: { detail: "bad input" }
    }

    wr = Fal::WebhookRequest.from_hash(payload)
    refute wr.success?
    assert wr.error?
    assert_equal "boom", wr.error
    assert_equal({ detail: "bad input" }, wr.response)
    assert_equal "bad input", wr.error_detail
  end
end
