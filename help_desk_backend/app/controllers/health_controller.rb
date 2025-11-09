class HealthController < ApplicationController
  def show
    render json: { status: "ok", timestamp: Time.now.utc.iso8601 } # :contentReference[oaicite:0]{index=0}
  end
end
