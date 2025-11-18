# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Tmdb
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class NotFoundError < Error; end
  class RateLimitError < Error; end
  class ServerError < Error; end

  class Client
    class << self
      def mutex
        @mutex ||= Mutex.new
      end

      def last_request_at
        @last_request_at ||= Process.clock_gettime(Process::CLOCK_MONOTONIC) - default_request_interval
      end

      def last_request_at=(value)
        @last_request_at = value
      end

      def default_request_interval
        Rails.application.config.x.tmdb.request_interval.to_f
      end
    end

    def initialize(api_key: Rails.application.config.x.tmdb.api_key,
                   base_url: Rails.application.config.x.tmdb.base_url,
                   language: Rails.application.config.x.tmdb.default_language,
                   request_interval: Rails.application.config.x.tmdb.request_interval)
      @api_key = api_key
      raise AuthenticationError, "TMDB API key is missing" if @api_key.blank?

      @base_url = base_url
      @language = language
      @request_interval = request_interval.to_f
    end

    def movie(id, **params)
      get("/movie/#{id}", params)
    end

    def get(path, params = {})
      enforce_rate_limit!

      uri = build_uri(path, params)
      response = perform_request(uri)

      parse_response(response)
    end

    private

    def enforce_rate_limit!
      return if @request_interval <= 0

      self.class.mutex.synchronize do
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        wait_time = (self.class.last_request_at + @request_interval) - now
        sleep(wait_time) if wait_time.positive?
        self.class.last_request_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end

    def build_uri(path, params)
      base_uri = URI.parse(@base_url)
      base_path = base_uri.path
      base_path = "#{base_path}/" unless base_path.end_with?("/")

      relative_path = path.to_s.delete_prefix("/")

      uri = base_uri.dup
      uri.path = File.join(base_path, relative_path)

      query = params.transform_keys(&:to_s)
      query["api_key"] ||= @api_key
      query["language"] ||= @language if @language.present?

      uri.query = URI.encode_www_form(query.compact)
      uri
    end

    def perform_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      if http.use_ssl?
        http.cert_store = build_cert_store
      end

      #  relax SSL when enabled so we can record VCR cassettes
      if ENV["TMDB_RELAX_SSL"] == "1"
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      http.open_timeout = 5
      http.read_timeout = 5

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"

      http.request(request)
    rescue Timeout::Error, Errno::ETIMEDOUT => error
      raise Error, "TMDB request timed out: #{error.message}"
    rescue SocketError => error
      raise Error, "TMDB connection failed: #{error.message}"
    rescue OpenSSL::SSL::SSLError => error
      message = "TMDB SSL connection failed: #{error.message}"
      if ENV["TMDB_RELAX_SSL"] != "1"
        message = "#{message}. Set TMDB_RELAX_SSL=1 to disable certificate verification in development if needed."
      end
      raise Error, message
    end


    def build_cert_store
      store = OpenSSL::X509::Store.new
      store.set_default_paths

      ca_file = ENV.fetch("TMDB_SSL_CA_FILE", ENV["SSL_CERT_FILE"])
      if ca_file.present?
        if File.file?(ca_file)
          store.add_file(ca_file)
        else
          Rails.logger&.warn("TMDB_SSL_CA_FILE is set but could not be found: #{ca_file}")
        end
      end

      store
    end


    def parse_response(response)
      case response
      when Net::HTTPSuccess
        parse_json(response.body)
      when Net::HTTPUnauthorized
        raise AuthenticationError, "TMDB authentication failed"
      when Net::HTTPNotFound
        raise NotFoundError, "TMDB resource not found"
      when Net::HTTPTooManyRequests
        raise RateLimitError, "TMDB rate limit exceeded"
      when Net::HTTPServerError
        raise ServerError, "TMDB server error: #{response.code}"
      else
        raise Error, "TMDB request failed with status #{response.code}"
      end
    end

    def parse_json(body)
      return {} if body.blank?

      JSON.parse(body)
    rescue JSON::ParserError => error
      raise Error, "TMDB response parsing failed: #{error.message}"
    end
  end
end
