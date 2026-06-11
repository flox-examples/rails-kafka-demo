Rails.application.routes.draw do
  resources :posts, only: %i[index create show]

  get "up", to: proc { [ 200, {}, [ "ok" ] ] }
end
