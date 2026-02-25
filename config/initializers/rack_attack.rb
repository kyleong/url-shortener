class Rack::Attack
  throttle("urls/create/ip", limit: 60, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/urls"
  end

  throttle("urls/create/session", limit: 60, period: 1.hour) do |req|
    req.session["session_id"] if req.post? && req.path == "/urls"
  end

  throttle("urls/redirect/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.get? && req.path.match?(%r{\A/[a-zA-Z0-9]+\z})
  end

  throttle("urls/show/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.get? && req.path.match?(%r{\A/urls/[a-zA-Z0-9]+\z})
  end

  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    retry_after = match_data[:period] - (Time.now.to_i % match_data[:period])

    headers = { "Content-Type" => "application/json" }
    body = { error: "Too many requests. Please try again later." }

    if defined?(Rails) && Rails.env.development?
      headers["Retry-After"] = retry_after.to_s
      body[:retry_after] = retry_after
    end

    [ 429, headers, [ body.to_json ] ]
  end
end
