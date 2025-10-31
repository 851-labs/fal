# frozen_string_literal: true

require "faraday"
require "time"
require "json"
require "cgi"
require "uri"

require_relative "fal/version"

module Fal
  # Base error class for all fal-related errors.
  class Error < StandardError; end
  # Raised when a request is unauthorized (HTTP 401).
  class UnauthorizedError < Error; end
  # Raised when a requested resource is not found (HTTP 404).
  class NotFoundError < Error; end
  # Raised when the server returns an unexpected error (HTTP 5xx or others).
  class ServerError < Error; end
  # Raised when the client is misconfigured.
  class ConfigurationError < Error; end
  # Raised when access is forbidden (HTTP 403).
  class ForbiddenError < Error; end

  # Global configuration for the fal client.
  class Configuration
    DEFAULT_QUEUE_BASE = "https://queue.fal.run"
    DEFAULT_SYNC_BASE = "https://fal.run"
    DEFAULT_API_BASE = "https://api.fal.ai/v1"
    DEFAULT_REQUEST_TIMEOUT = 120

    # API key used for authenticating with fal endpoints.
    # Defaults to ENV["FAL_KEY"].
    # @return [String]
    attr_accessor :api_key

    # Base URL for fal queue endpoints.
    # @return [String]
    attr_accessor :queue_base

    # Base URL for synchronous streaming endpoints (fal.run).
    # @return [String]
    attr_accessor :sync_base

    # Base URL for platform API endpoints (api.fal.ai/v1).
    # @return [String]
    attr_accessor :api_base

    # Timeout in seconds for opening and processing HTTP requests.
    # @return [Integer]
    attr_accessor :request_timeout

    # Initialize configuration with sensible defaults.
    # @return [Fal::Configuration]
    def initialize
      @api_key = ENV.fetch("FAL_KEY", nil)
      @queue_base = DEFAULT_QUEUE_BASE
      @sync_base = DEFAULT_SYNC_BASE
      @api_base = DEFAULT_API_BASE
      @request_timeout = DEFAULT_REQUEST_TIMEOUT
    end
  end

  class << self
    # The global configuration instance.
    # @return [Fal::Configuration]
    attr_accessor :configuration

    # Configure the fal client.
    # @yield [Fal::Configuration] the configuration object to mutate
    # @return [void]
    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    # Global client accessor using the configured settings.
    # @return [Fal::Client]
    def client
      configuration = self.configuration || Configuration.new
      @client ||= Fal::Client.new(configuration)
    end

    # Deep symbolize keys of a Hash or Array.
    # @param obj [Hash, Array]
    # @return [Hash, Array]
    def deep_symbolize_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), result|
          key = k.is_a?(String) ? k.to_sym : k
          result[key] = deep_symbolize_keys(v)
        end
      when Array
        obj.map { |e| deep_symbolize_keys(e) }
      else
        obj
      end
    end
  end
end

require_relative "fal/client"
require_relative "fal/request"
require_relative "fal/stream"
require_relative "fal/webhook_request"
require_relative "fal/price"
require_relative "fal/price_estimate"
require_relative "fal/model"
