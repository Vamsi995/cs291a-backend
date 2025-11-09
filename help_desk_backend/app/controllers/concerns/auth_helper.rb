module AuthHelper
  SECRET = Rails.application.credentials.jwt_secret || ENV["JWT_SECRET"] || "dev_secret"

  def encode_token(payload)
    JWT.encode(payload, SECRET, "HS256")
  end

  def decoded_token
    header = request.headers["Authorization"]
    token  = header&.split("Bearer ")&.last
    token ||= cookies.signed[:session_jwt] # session-based path
    return nil unless token
    JWT.decode(token, SECRET, true, algorithm: "HS256")[0]
  rescue JWT::DecodeError
    nil
  end

  def current_user
    @current_user ||= (User.find_by(id: decoded_token&.dig("user_id")) if decoded_token)
  end

  def authenticate!
    return if current_user
    render json: { error: "Authentication required" }, status: :unauthorized
  end
end
