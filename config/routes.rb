Rails.application.routes.draw do
  devise_for :users
  root to: 'pages#home'
  
  get "linkedin_callback", to: "pages#linkedin", as: "linkedin"
end
