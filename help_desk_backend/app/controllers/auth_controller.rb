class AuthController < ApplicationController
  include ::AuthHelper
  # register / login are public
  def register
    user = User.new(username: params[:username], password: params[:password])
    if user.save
      token = encode_token(user_id: user.id)
      cookies.signed[:session_jwt] = { value: token, httponly: true }
      render json: { user: user.as_json(only: [:id, :username, :created_at, :last_active_at]),
                     token: token }, status: :created # :contentReference[oaicite:1]{index=1}
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity # :contentReference[oaicite:2]{index=2}
    end
  end

  def login
    user = User.find_by(username: params[:username])
    if user&.authenticate(params[:password])
      user.touch(:last_active_at)
      token = encode_token(user_id: user.id)
      cookies.signed[:session_jwt] = { value: token, httponly: true }
      render json: { user: user.as_json(only: [:id, :username, :created_at, :last_active_at]),
                     token: token } # :contentReference[oaicite:3]{index=3}
    else
      render json: { error: "Invalid username or password" }, status: :unauthorized # :contentReference[oaicite:4]{index=4}
    end
  end

  def logout
    cookies.delete(:session_jwt)
    render json: { message: "Logged out successfully" } # :contentReference[oaicite:5]{index=5}
  end

  def refresh
    authenticate!
    token = encode_token(user_id: current_user.id)
    cookies.signed[:session_jwt] = { value: token, httponly: true }
    render json: { user: current_user.as_json(only: [:id, :username, :created_at, :last_active_at]),
                   token: token } # :contentReference[oaicite:6]{index=6}
  end

  def me
    authenticate!
    render json: current_user.as_json(only: [:id, :username, :created_at, :last_active_at]) # :contentReference[oaicite:7]{index=7}
  end
end
