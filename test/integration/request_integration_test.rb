# frozen_string_literal: true

require "test_helper"

class RequestIntegrationTest < Minitest::Test
  ENDPOINT_ID = "fal-ai/flux/dev"

  def test_request_lifecycle_create_status_logs_cancel
    request = Fal::Request.create!(endpoint_id: ENDPOINT_ID, input: { prompt: "a cat" })
    refute_nil request.id

    # First status (may be IN_QUEUE or IN_PROGRESS)
    request.reload!
    assert [Fal::Request::Status::IN_QUEUE, Fal::Request::Status::IN_PROGRESS, Fal::Request::Status::COMPLETED].include?(request.status)

    # With logs
    request.reload!(logs: true)
    # Logs may be nil until processing starts, so just assert no error
    assert_includes [nil, Array], request.logs.class

    # Cancel (if already completed, server may ignore cancel; just assert response structure)
    response = request.cancel!
    assert_kind_of Hash, response
  end

  def test_find_by_fetches_status_with_logs
    created = Fal::Request.create!(endpoint_id: ENDPOINT_ID, input: { prompt: "a dog" })
    found = Fal::Request.find_by!(id: created.id, endpoint_id: ENDPOINT_ID, logs: true)

    assert_equal created.id, found.id
    assert [Fal::Request::Status::IN_QUEUE, Fal::Request::Status::IN_PROGRESS, Fal::Request::Status::COMPLETED].include?(found.status)
    assert_includes [nil, Array], found.logs.class
  end

  def test_reload_fetches_response_when_completed
    request = Fal::Request.create!(endpoint_id: ENDPOINT_ID, input: { prompt: "final response" })

    20.times do
      request.reload!
      break if request.completed?

      sleep 1
    end

    if request.completed?
      refute_nil request.response
    else
      skip "Request did not complete during recording window"
    end
  end
end
