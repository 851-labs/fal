# typed: strict
# frozen_string_literal: true

module Fal
  class Error < StandardError; end
  class UnauthorizedError < Error; end
  class NotFoundError < Error; end
  class ServerError < Error; end
  class ConfigurationError < Error; end
  class ForbiddenError < Error; end

  class Configuration
    # api_key
    sig { returns(T.nilable(String)) }
    def api_key; end

    sig { params(value: T.nilable(String)).returns(T.nilable(String)) }
    def api_key=(value); end

    # queue_base
    sig { returns(String) }
    def queue_base; end

    sig { params(value: String).returns(String) }
    def queue_base=(value); end

    # sync_base
    sig { returns(String) }
    def sync_base; end

    sig { params(value: String).returns(String) }
    def sync_base=(value); end

    # api_base
    sig { returns(String) }
    def api_base; end

    sig { params(value: String).returns(String) }
    def api_base=(value); end

    # request_timeout
    sig { returns(Integer) }
    def request_timeout; end

    sig { params(value: Integer).returns(Integer) }
    def request_timeout=(value); end

    sig { void }
    def initialize; end
  end

  class << self
    sig { returns(Fal::Configuration) }
    def configuration; end

    sig { params(value: Fal::Configuration).returns(Fal::Configuration) }
    def configuration=(value); end

    sig { params(block: T.proc.params(arg0: Fal::Configuration).void).void }
    def configure(&block); end

    sig { returns(Fal::Client) }
    def client; end

    sig { params(obj: T.untyped).returns(T.untyped) }
    def deep_symbolize_keys(obj); end
  end
end
