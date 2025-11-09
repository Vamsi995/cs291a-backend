Rails.application.routes.draw do
  get  "/health", to: "health#show"

  scope :auth do
    post "/register", to: "auth#register"
    post "/login",    to: "auth#login"
    post "/logout",   to: "auth#logout"
    post "/refresh",  to: "auth#refresh"
    get  "/me",       to: "auth#me"
  end

  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:index]
  end

  resources :messages, only: [:create] do
    member { put :read }
  end

  scope :expert do
    get  "/queue",                                      to: "expert#queue"
    post "/conversations/:conversation_id/claim",       to: "expert#claim"
    post "/conversations/:conversation_id/unclaim",     to: "expert#unclaim"
    get  "/profile",                                    to: "expert#profile"
    put  "/profile",                                    to: "expert#update_profile"
    get  "/assignments/history",                        to: "expert#history"
  end

  scope :api do
    get "/conversations/updates", to: "updates#conversations"
    get "/messages/updates",      to: "updates#messages"
    get "/expert-queue/updates",  to: "updates#expert_queue"
  end
end