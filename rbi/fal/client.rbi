# typed: strict
# frozen_string_literal: true

module Fal
  class Client
    sig { returns(Fal::Configuration) }
    def configuration; end

    sig { params(value: Fal::Configuration).returns(Fal::Configuration) }
    def configuration=(value); end

    sig { params(configuration: T.nilable(Fal::Configuration)).void }
    def initialize(configuration = nil); end

    sig { params(path: String, payload: T.untyped, headers: T.untyped).returns(T.untyped) }
    def post(path, payload = nil, headers: {}); end

    sig do
      params(
        path: String,
        payload: T.untyped,
        on_data: T.proc.params(arg0: String, arg1: T.untyped).void
      ).void
    end
    def post_stream(path, payload = nil, on_data:); end

    sig { params(path: String, query: T.untyped, headers: T.untyped).returns(T.untyped) }
    def get(path, query: nil, headers: {}); end

    sig { params(path: String, query: T.untyped, headers: T.untyped).returns(T.untyped) }
    def get_api(path, query: nil, headers: {}); end

    sig { params(path: String, payload: T.untyped, headers: T.untyped).returns(T.untyped) }
    def post_api(path, payload = nil, headers: {}); end

    sig { params(path: String).returns(T.untyped) }
    def put(path); end

    sig { params(response: T.untyped).void }
    def handle_error(response); end

    private

    sig { params(body: T.untyped).returns(T.untyped) }
    def parse_json(body); end

    sig { params(path: String).returns(String) }
    def build_url(path); end

    sig { params(path: String).returns(String) }
    def build_sync_url(path); end

    sig { params(path: String).returns(String) }
    def build_api_url(path); end

    sig { returns(T.untyped) }
    def connection; end
  end
end
