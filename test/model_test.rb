# frozen_string_literal: true

require "test_helper"

class ModelTest < Minitest::Test
  class FakeClient
    def initialize(stubs: {})
      @stubs = stubs
      @configuration = Fal::Configuration.new
    end

    def get_api(path, query: nil, headers: {})
      key = query && !query.empty? ? [path, query] : [path]
      call(:get_api, key, nil, headers)
    end

    def post(path, payload = nil, headers: {})
      call(:post, path, payload, headers)
    end

    private

    def call(method, path_or_key, payload, headers)
      key = case method
            when :get_api then [:get_api, *Array(path_or_key)]
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

  def test_find_by_returns_model
    endpoint_id = "fal-ai/flux/dev"
    stubs = {
      [:get_api, "/models", { endpoint_id: endpoint_id }] => {
        "models" => [{ "endpoint_id" => endpoint_id }],
        "next_cursor" => nil,
        "has_more" => false
      }
    }

    client = FakeClient.new(stubs: stubs)
    model = Fal::Model.find_by(endpoint_id: endpoint_id, client: client)

    refute_nil model
    assert_equal endpoint_id, model.endpoint_id
  end

  def test_each_and_all_with_search_filters
    page1 = {
      "models" => [{ "endpoint_id" => "a" }, { "endpoint_id" => "b" }],
      "next_cursor" => "Mg==",
      "has_more" => true
    }
    page2 = {
      "models" => [{ "endpoint_id" => "c" }],
      "next_cursor" => nil,
      "has_more" => false
    }

    stubs = {
      [:get_api, "/models", { limit: 50, q: "text to image" }] => page1,
      [:get_api, "/models", { limit: 50, cursor: "Mg==", q: "text to image" }] => page2
    }

    client = FakeClient.new(stubs: stubs)

    yielded = []
    Fal::Model.each(client: client, query: "text to image") { |m| yielded << m.endpoint_id }
    assert_equal %w[a b c], yielded

    all = Fal::Model.all(client: client, query: "text to image")
    assert_equal %w[a b c], all.map(&:endpoint_id)
  end

  def test_metadata_is_flattened_to_top_level_attributes
    endpoint_id = "fal-ai/flux/dev"
    attributes = {
      "endpoint_id" => endpoint_id,
      "metadata" => {
        "display_name" => "FLUX.1 [dev]",
        "category" => "text-to-image",
        "description" => "Fast text-to-image generation",
        "status" => "active",
        "tags" => %w[fast pro],
        "updated_at" => "2025-01-15T12:00:00Z",
        "is_favorited" => false,
        "thumbnail_url" => "https://fal.media/img.jpg",
        "thumbnail_animated_url" => "https://fal.media/anim.gif",
        "model_url" => "https://fal.run/fal-ai/flux/dev",
        "github_url" => "https://github.com/fal-ai/flux",
        "license_type" => "commercial",
        "date" => "2024-08-01T00:00:00Z",
        "group" => { "key" => "flux", "label" => "FLUX" },
        "highlighted" => true,
        "kind" => "inference",
        "training_endpoint_ids" => ["trainer/x"],
        "inference_endpoint_ids" => ["fal-ai/flux/dev"],
        "stream_url" => "https://fal.run/stream",
        "duration_estimate" => 2.5,
        "pinned" => false
      }
    }

    client = FakeClient.new(stubs: {})
    model = Fal::Model.new(attributes, client: client)

    assert_equal endpoint_id, model.endpoint_id
    assert_equal "FLUX.1 [dev]", model.display_name
    assert_equal "text-to-image", model.category
    assert_equal "Fast text-to-image generation", model.description
    assert_equal "active", model.status
    assert_equal %w[fast pro], model.tags
    assert_equal "2025-01-15T12:00:00Z", model.updated_at
    assert_equal false, model.is_favorited
    assert_equal "https://fal.media/img.jpg", model.thumbnail_url
    assert_equal "https://fal.media/anim.gif", model.thumbnail_animated_url
    assert_equal "https://fal.run/fal-ai/flux/dev", model.model_url
    assert_equal "https://github.com/fal-ai/flux", model.github_url
    assert_equal "commercial", model.license_type
    assert_equal "2024-08-01T00:00:00Z", model.date
    refute_nil model.group
    assert_equal true, model.highlighted
    assert_equal "inference", model.kind
    assert_equal ["trainer/x"], model.training_endpoint_ids
    assert_equal ["fal-ai/flux/dev"], model.inference_endpoint_ids
    assert_equal "https://fal.run/stream", model.stream_url
    assert_in_delta 2.5, model.duration_estimate, 0.00001
    assert_equal false, model.pinned
  end

  def test_price_is_memoized
    endpoint_id = "fal-ai/flux/dev"
    calls = 0
    stubs = {
      [:get_api, "/models/pricing", { endpoint_id: endpoint_id }] => lambda do |_payload, _headers|
        calls += 1
        {
          "prices" => [{ "endpoint_id" => endpoint_id, "unit_price" => 0.025, "unit" => "image",
                         "currency" => "USD" }],
          "next_cursor" => nil,
          "has_more" => false
        }
      end
    }

    client = FakeClient.new(stubs: stubs)
    model = Fal::Model.new({ "endpoint_id" => endpoint_id }, client: client)

    p1 = model.price
    p2 = model.price
    assert_same p1, p2
    assert_equal 1, calls
  end

  def test_instance_run_uses_endpoint_id
    endpoint_id = "fal-ai/flux/dev"
    stubs = {
      [:post, "/#{endpoint_id}"] => { "request_id" => "xyz789", "status" => Fal::Request::Status::IN_QUEUE }
    }
    client = FakeClient.new(stubs: stubs)
    model = Fal::Model.new({ "endpoint_id" => endpoint_id }, client: client)

    request = model.run(input: { prompt: "hello" })
    assert_kind_of Fal::Request, request
    assert_equal "xyz789", request.id
  end
end
