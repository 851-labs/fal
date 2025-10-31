# frozen_string_literal: true

require "test_helper"

class PriceTest < Minitest::Test
  class FakeClient
    def initialize(stubs: {})
      @stubs = stubs
      @configuration = Fal::Configuration.new
    end

    def get_api(path, query: nil, headers: {})
      key = query && !query.empty? ? [path, query] : [path]
      call(:get_api, key, nil, headers)
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

  def test_find_by_returns_price
    endpoint_id = "fal-ai/flux/dev"
    stubs = {
      [:get_api, "/models/pricing", { endpoint_id: endpoint_id }] => {
        "prices" => [
          { "endpoint_id" => endpoint_id, "unit_price" => 0.025, "unit" => "image", "currency" => "USD" }
        ],
        "next_cursor" => nil,
        "has_more" => false
      }
    }

    client = FakeClient.new(stubs: stubs)
    price = Fal::Price.find_by(endpoint_id: endpoint_id, client: client)

    refute_nil price
    assert_equal endpoint_id, price.endpoint_id
    assert_equal 0.025, price.unit_price
    assert_equal "image", price.unit
    assert_equal "USD", price.currency
  end

  def test_each_and_all_paginate_models_and_fetch_prices
    page1_models = {
      "models" => [
        { "endpoint_id" => "a" },
        { "endpoint_id" => "b" }
      ],
      "next_cursor" => "Mg==",
      "has_more" => true
    }
    page2_models = {
      "models" => [
        { "endpoint_id" => "c" }
      ],
      "next_cursor" => nil,
      "has_more" => false
    }

    stubs = {
      [:get_api, "/models", { limit: 50 }] => page1_models,
      [:get_api, "/models", { limit: 50, cursor: "Mg==" }] => page2_models,
      [:get_api, "/models/pricing", { endpoint_id: %w[a b] }] => {
        "prices" => [
          { "endpoint_id" => "a", "unit_price" => 1.0, "unit" => "image", "currency" => "USD" },
          { "endpoint_id" => "b", "unit_price" => 2.0, "unit" => "video", "currency" => "USD" }
        ],
        "next_cursor" => nil,
        "has_more" => false
      },
      [:get_api, "/models/pricing", { endpoint_id: ["c"] }] => {
        "prices" => [
          { "endpoint_id" => "c", "unit_price" => 3.0, "unit" => "image", "currency" => "USD" }
        ],
        "next_cursor" => nil,
        "has_more" => false
      }
    }

    client = FakeClient.new(stubs: stubs)

    yielded = []
    Fal::Price.each(client: client) { |p| yielded << p.endpoint_id }
    assert_equal %w[a b c], yielded

    all = Fal::Price.all(client: client)
    assert_equal 3, all.size
    assert_equal %w[a b c], all.map(&:endpoint_id)
  end
end
