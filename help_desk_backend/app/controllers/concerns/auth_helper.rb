# module AuthHelper
#   SECRET = Rails.application.credentials.jwt_secret || ENV["JWT_SECRET"] || "dev_secret"

#   def encode_token(payload)
#     JWT.encode(payload, SECRET, "HS256")
#   end

#   def decoded_token
#     header = request.headers["Authorization"]
#     token  = header&.split("Bearer ")&.last
#     token ||= cookies.signed[:session_jwt] # session-based path
#     return nil unless token
#     JWT.decode(token, SECRET, true, algorithm: "HS256")[0]
#   rescue JWT::DecodeError
#     nil
#   end

#   def current_user
#     @current_user ||= (User.find_by(id: decoded_token&.dig("user_id")) if decoded_token)
#   end

#   def authenticate!
#     return if current_user
#     render json: { error: "Authentication required" }, status: :unauthorized
#   end
# end
# app/controllers/concerns/auth_helper.rb
module AuthHelper
  SECRET    = Rails.application.credentials.jwt_secret || ENV["JWT_SECRET"] || "dev_secret"
  ALGORITHM = "HS256"
  TTL       = 24.hours

  # Issue a JWT with an exp claim
  def encode_token(payload)
    payload = payload.merge(exp: TTL.from_now.to_i)
    JWT.encode(payload, SECRET, ALGORITHM)
  end

  # Decode the Bearer token; return payload hash or nil
  def decoded_token
    token = bearer_token
    return nil unless token
    decoded = JWT.decode(token, SECRET, true, algorithm: ALGORITHM)
    decoded.first
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end

  # Current user from token
  def current_user
    @current_user ||= begin
      payload = decoded_token
      User.find_by(id: payload["user_id"]) if payload
    end
  end

  # before_action guard
  def authenticate!
    return if current_user
    render json: { error: "Authentication required" }, status: :unauthorized
  end

  private

  # Extract "Bearer <token>" from Authorization header
  def bearer_token
    header = request.headers["Authorization"].to_s
    return nil if header.empty?
    scheme, token = header.split(" ", 2)
    return token if scheme&.casecmp("Bearer")&.zero?
    nil
  end
end
