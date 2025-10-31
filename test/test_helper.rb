# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "dotenv/load"
require "minitest/autorun"
require "vcr"
require "webmock/minitest"

# VCR configuration to record and replay HTTP interactions
VCR.configure do |c|
  c.cassette_library_dir = File.join(__dir__, "vcr_cassettes")
  c.hook_into :webmock

  # Avoid outbound HTTP without an active cassette
  c.allow_http_connections_when_no_cassette = false

  # Default recording mode: never record unless explicitly overridden
  default_record_mode = ENV["VCR_RECORD"]&.to_sym || :none
  c.default_cassette_options = {
    record: default_record_mode,
    match_requests_on: %i[method uri body]
  }

  # Scrub secrets
  c.filter_sensitive_data("<FAL_KEY>") { Fal.configuration&.api_key || ENV.fetch("FAL_KEY", nil) }
  c.filter_sensitive_data("<AUTHORIZATION>") do |interaction|
    Array(interaction.request.headers["Authorization"]).first
  end

  # Localhost is not part of external API interactions
  c.ignore_hosts "127.0.0.1", "localhost"
end

module Minitest
  class Test
    # Automatically wrap each test in a VCR cassette named by class/method
    def before_setup
      super
      cassette_name = [self.class.name, name].join("/")
      VCR.insert_cassette(cassette_name)
    end

    def after_teardown
      VCR.eject_cassette
      super
    end
  end
end

require "fal"
