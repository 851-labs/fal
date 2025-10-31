# frozen_string_literal: true

module Fal
  class Client
    attr_accessor :configuration

    def initialize(configuration = Fal.configuration)
      @configuration = configuration
    end

    def post(path, payload = {}, headers: {})
      response = connection.post(build_url(path)) do |request|
        request.headers["Authorization"] = "Key #{@configuration.api_key}" if @configuration.api_key
        request.headers["Content-Type"] = "application/json"
        request.headers["Accept"] = "application/json"
        request.headers.merge!(headers)
        request.body = payload.compact.to_json
      end

      handle_error(response) unless response.success?

      parse_json(response.body)
    end

    # Perform a POST against the platform API base (api.fal.ai/v1)
    # @param path [String]
    # @param payload [Hash]
    # @param headers [Hash]
    # @return [Hash, nil]
    def post_api(path, payload = {}, headers: {})
      response = connection.post(build_api_url(path)) do |request|
        request.headers["Authorization"] = "Key #{@configuration.api_key}" if @configuration.api_key
        request.headers["Content-Type"] = "application/json"
        request.headers["Accept"] = "application/json"
        request.headers.merge!(headers)
        request.body = payload.compact.to_json
      end

      handle_error(response) unless response.success?

      parse_json(response.body)
    end

    # Perform a POST to the streaming (sync) base with SSE/text-event-stream handling.
    # The provided on_data Proc will be used to receive chunked data.
    # @param path [String]
    # @param payload [Hash]
    # @param on_data [Proc] called with chunks as they arrive
    # @return [void]
    def post_stream(path, payload = {}, on_data:)
      url = build_sync_url(path)
      connection.post(url) do |request|
        request.headers["Authorization"] = "Key #{@configuration.api_key}" if @configuration.api_key
        request.headers["Accept"] = "text/event-stream"
        request.headers["Cache-Control"] = "no-store"
        request.headers["Content-Type"] = "application/json"
        request.body = payload.compact.to_json
        request.options.on_data = on_data
      end
    end

    def get(path, query: nil, headers: {})
      url = build_url(path)
      url = "#{url}?#{URI.encode_www_form(query)}" if query && !query.empty?

      response = connection.get(url) do |request|
        request.headers["Authorization"] = "Key #{@configuration.api_key}" if @configuration.api_key
        request.headers["Accept"] = "application/json"
        request.headers.merge!(headers)
      end

      handle_error(response) unless response.success?

      parse_json(response.body)
    end

    # Perform a GET against the platform API base (api.fal.ai/v1)
    # @param path [String]
    # @param query [Hash, nil]
    # @param headers [Hash]
    # @return [Hash, nil]
    def get_api(path, query: nil, headers: {})
      url = build_api_url(path)
      url = "#{url}?#{URI.encode_www_form(query)}" if query && !query.empty?

      response = connection.get(url) do |request|
        request.headers["Authorization"] = "Key #{@configuration.api_key}" if @configuration.api_key
        request.headers["Accept"] = "application/json"
        request.headers.merge!(headers)
      end

      handle_error(response) unless response.success?

      parse_json(response.body)
    end

    def put(path)
      response = connection.put(build_url(path)) do |request|
        request.headers["Authorization"] = "Key #{@configuration.api_key}" if @configuration.api_key
        request.headers["Content-Type"] = "application/json"
        request.headers["Accept"] = "application/json"
        request.body = {}.to_json
      end

      handle_error(response) unless response.success?

      parse_json(response.body)
    end

    def handle_error(response)
      case response.status
      when 401
        raise UnauthorizedError, response.body
      when 403
        raise ForbiddenError, response.body
      when 404
        raise NotFoundError, response.body
      else
        raise ServerError, response.body
      end
    end

    private

    def parse_json(body)
      return nil if body.nil? || body.strip.empty?

      JSON.parse(body)
    end

    def build_url(path)
      "#{@configuration.queue_base}#{path}"
    end

    def build_sync_url(path)
      "#{@configuration.sync_base}#{path}"
    end

    def build_api_url(path)
      "#{@configuration.api_base}#{path}"
    end

    def connection
      Faraday.new do |faraday|
        faraday.request :url_encoded
        faraday.options.timeout = @configuration.request_timeout
        faraday.options.open_timeout = @configuration.request_timeout
      end
    end
  end
end
