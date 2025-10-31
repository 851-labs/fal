# typed: strict
# frozen_string_literal: true

module Fal
  class Stream
    sig { returns(String) }
    def path; end

    sig do
      params(
        path: String,
        input: T.untyped,
        client: Fal::Client
      ).void
    end
    def initialize(path:, input:, client: Fal.client); end

    sig do
      params(block: T.proc.params(arg0: T.untyped)
      .void).void
    end
    def each(&block); end

    class SSEDecoder
      sig { void }
      def initialize; end

      sig { params(line: String).returns(T.untyped) }
      def decode(line); end

      private

      sig { returns(T.untyped) }
      def flush_event; end
    end
  end
end
