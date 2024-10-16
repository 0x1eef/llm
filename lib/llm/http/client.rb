# frozen_string_literal: true

module LLM
  require "llm/error"

  module HTTPClient
    def post(req)
      req.content_type = "application/json"
      res = request(req)
      res.tap(&:value)
    rescue Net::HTTPClientException
      if [
        Net::HTTPBadRequest,   # Gemini (huh?)
        Net::HTTPForbidden,    # Anthropic
        Net::HTTPUnauthorized  # OpenAI
      ].any? { _1 === res }
        raise LLM::Error::Unauthorized.new { _1.response = res }, "Authentication error"
      elsif Net::HTTPTooManyRequests === res
        raise LLM::Error::RateLimit.new { _1.response = res }, "Too many requests"
      else
        raise LLM::Error::HTTPError.new { _1.response = res }, "Unexpected response"
      end
    end
  end
end
