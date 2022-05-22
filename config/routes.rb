Rails.application.routes.draw do
  #devise_for :users
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  # root "home#index"

  # Cognito will call this endpoint to check user name and password
  post '/aws/auth',
   to: 'users/sessions#aws_auth',
   defaults: {format: 'json'},
   as: 'aws_auth'
end
