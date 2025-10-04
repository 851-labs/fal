# frozen_string_literal: true

module Fal
  # Streaming helper for Server-Sent Events from fal.run synchronous endpoints.
  # It parses SSE lines and yields decoded event hashes with symbolized keys.
  class Stream
    # @return [String] endpoint path under fal.run, e.g. "/fal-ai/flux/dev/stream"
    attr_reader :path

    # @param path [String] full path under sync_base (leading slash), ex: "/fal-ai/flux/dev/stream"
    # @param input [Hash] request input payload
    # @param client [Fal::Client] HTTP client
    def initialize(path:, input:, client: Fal.client)
      @path = path
      @input = input
      @client = client
    end

    # Stream events; yields a Hash for each event data chunk. Blocks until stream ends.
    # @yield [event] yields decoded event hash
    # @yieldparam event [Hash]
    # @return [void]
    def each(&block)
      buffer = ""
      decoder = SSEDecoder.new

      @client.post_stream(@path, @input, on_data: proc do |chunk, _total_bytes|
        buffer = (buffer + chunk).gsub(/\r\n?/, "\n")
        lines = buffer.split("\n", -1)
        buffer = lines.pop || ""
        lines.each do |line|
          event = decoder.decode(line)
          block.call(event) if event
        end
      end)
    end

    # Minimal SSE decoder for parsing standard server-sent event stream lines.
    class SSEDecoder
      def initialize
        @event = ""
        @data = ""
        @id = nil
        @retry = nil
      end

      # @param line [String]
      # @return [Hash, nil]
      def decode(line)
        return flush_event if line.empty?
        return if line.start_with?(":")

        field, _, value = line.partition(":")
        value = value.lstrip

        case field
        when "event"
          @event = value
        when "data"
          @data += "#{value}\n"
        when "id"
          @id = value
        when "retry"
          @retry = value.to_i
        end

        nil
      end

      private

      def flush_event
        return if @data.empty?

        data = @data.chomp
        parsed = JSON.parse(data)

        event = { "data" => parsed }
        event["event"] = @event unless @event.empty?
        event["id"] = @id if @id
        event["retry"] = @retry if @retry

        @event = ""
        @data = ""
        @id = nil
        @retry = nil

        event
      end
    end
  end
end
