# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tmdb::Client do
  let(:client) do
    described_class.new(
      api_key: ENV.fetch("TMDB_API_KEY", "test_api_key"),
      request_interval: 0
    )
  end

  describe "#movie" do
    it "fetches movie details and returns parsed JSON" do
      movie = VCR.use_cassette("tmdb/movie_success") do
        client.movie(550)
      end

      expect(movie["id"]).to eq(550)
      expect(movie["title"]).to eq("Fight Club")
    end

    it "raises not found error for missing movie" do
      expect {
        VCR.use_cassette("tmdb/movie_not_found") do
          client.movie(0)
        end
      }
       .to raise_error(Tmdb::NotFoundError, /not found/i)
    end

    it "uses the system certificate store for HTTPS requests" do
      cert_store = instance_double(OpenSSL::X509::Store, set_default_paths: true, add_file: true)
      allow(OpenSSL::X509::Store).to receive(:new).and_return(cert_store)

      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).with("api.themoviedb.org", 443).and_return(http)

      allow(http).to receive(:use_ssl?).and_return(true)
      allow(http).to receive(:use_ssl=).with(true)
      allow(http).to receive(:cert_store=).with(cert_store)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)

      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return("{}")
      allow(http).to receive(:request).and_return(response)

      client.movie(550)

      expect(cert_store).to have_received(:set_default_paths)
      expect(http).to have_received(:cert_store=).with(cert_store)
    end

    it "disables SSL verification when requested" do
      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=).with(true)
      allow(http).to receive(:use_ssl?).and_return(true)
      allow(http).to receive(:cert_store=)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)

      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return("{}")
      allow(http).to receive(:request).and_return(response)

      original_env = ENV["TMDB_RELAX_SSL"]
      begin
        ENV["TMDB_RELAX_SSL"] = "1"
        client.movie(550)
      ensure
        ENV["TMDB_RELAX_SSL"] = original_env
      end

      expect(http).to have_received(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
    end
  end

  describe ".new" do
    it "raises authentication error when api key missing" do
      expect { described_class.new(api_key: nil) }
        .to raise_error(Tmdb::AuthenticationError, /missing/i)
    end
  end

  describe "#get error handling" do
    it "raises Error on timeout" do
      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:use_ssl?).and_return(false)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:request).and_raise(Timeout::Error.new("timed out"))

      expect { client.get("/test") }.to raise_error(Tmdb::Error, /timed out/i)
    end

    it "raises Error on socket error" do
      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:use_ssl?).and_return(false)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:request).and_raise(SocketError.new("connection failed"))

      expect { client.get("/test") }.to raise_error(Tmdb::Error, /connection failed/i)
    end

    it "raises Error on SSL error" do
      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:use_ssl?).and_return(false)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:request).and_raise(OpenSSL::SSL::SSLError.new("SSL failed"))

      expect { client.get("/test") }.to raise_error(Tmdb::Error, /SSL.*failed/i)
    end
  end

  describe "#build_cert_store" do
    it "adds CA file when TMDB_SSL_CA_FILE is set and file exists" do
      cert_store = instance_double(OpenSSL::X509::Store, set_default_paths: true)
      allow(OpenSSL::X509::Store).to receive(:new).and_return(cert_store)
      allow(cert_store).to receive(:add_file)

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("TMDB_SSL_CA_FILE", anything).and_return("/tmp/test_ca.pem")
      allow(File).to receive(:file?).with("/tmp/test_ca.pem").and_return(true)

      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:use_ssl?).and_return(true)
      allow(http).to receive(:cert_store=)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)

      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return("{}")
      allow(http).to receive(:request).and_return(response)

      client.get("/test")

      expect(cert_store).to have_received(:add_file).with("/tmp/test_ca.pem")
    end

    it "logs warning when TMDB_SSL_CA_FILE is set but file does not exist" do
      cert_store = instance_double(OpenSSL::X509::Store, set_default_paths: true)
      allow(OpenSSL::X509::Store).to receive(:new).and_return(cert_store)

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("TMDB_SSL_CA_FILE", anything).and_return("/nonexistent/ca.pem")
      allow(File).to receive(:file?).with("/nonexistent/ca.pem").and_return(false)
      allow(Rails.logger).to receive(:warn)

      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:use_ssl?).and_return(true)
      allow(http).to receive(:cert_store=)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)

      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return("{}")
      allow(http).to receive(:request).and_return(response)

      client.get("/test")

      expect(Rails.logger).to have_received(:warn).with(/TMDB_SSL_CA_FILE.*could not be found/)
    end
  end

  describe "#parse_response" do
    let(:http) { instance_double(Net::HTTP) }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:use_ssl?).and_return(false)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
    end

    it "raises AuthenticationError on 401" do
      response = Net::HTTPUnauthorized.new("1.1", "401", "Unauthorized")
      allow(http).to receive(:request).and_return(response)

      expect { client.get("/test") }.to raise_error(Tmdb::AuthenticationError, /authentication failed/i)
    end

    it "raises NotFoundError on 404" do
      response = Net::HTTPNotFound.new("1.1", "404", "Not Found")
      allow(http).to receive(:request).and_return(response)

      expect { client.get("/test") }.to raise_error(Tmdb::NotFoundError, /not found/i)
    end

    it "raises RateLimitError on 429" do
      response = Net::HTTPTooManyRequests.new("1.1", "429", "Too Many Requests")
      allow(http).to receive(:request).and_return(response)

      expect { client.get("/test") }.to raise_error(Tmdb::RateLimitError, /rate limit/i)
    end

    it "raises ServerError on 5xx" do
      response = Net::HTTPInternalServerError.new("1.1", "500", "Internal Server Error")
      allow(response).to receive(:code).and_return("500")
      allow(http).to receive(:request).and_return(response)

      expect { client.get("/test") }.to raise_error(Tmdb::ServerError, /server error/i)
    end

    it "raises Error on other status codes" do
      response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
      allow(response).to receive(:code).and_return("400")
      allow(http).to receive(:request).and_return(response)

      expect { client.get("/test") }.to raise_error(Tmdb::Error, /failed with status 400/i)
    end
  end

  describe "#parse_json" do
    let(:http) { instance_double(Net::HTTP) }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:use_ssl?).and_return(false)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)
    end

    it "raises Error on invalid JSON" do
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return("not valid json {{{")
      allow(http).to receive(:request).and_return(response)

      expect { client.get("/test") }.to raise_error(Tmdb::Error, /parsing failed/i)
    end

    it "returns empty hash when body is blank" do
      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return("")
      allow(http).to receive(:request).and_return(response)

      expect(client.get("/test")).to eq({})
    end
  end

  describe "rate limiting" do
    it "sleeps when the interval has not elapsed" do
      throttled_client = described_class.new(api_key: "test_key", request_interval: 0.1)
      allow(throttled_client.class).to receive(:mutex).and_return(Mutex.new)

      # Force last request to be very recent
      throttled_client.class.last_request_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:use_ssl?).and_return(false)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)

      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return("{}")
      allow(http).to receive(:request).and_return(response)

      allow(throttled_client).to receive(:sleep)

      throttled_client.get("/test")

      expect(throttled_client).to have_received(:sleep).with(be > 0)
    end
  end
end
