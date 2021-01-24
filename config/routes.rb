Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root 'root#index'
  resources :people, only: [:index, :show]
  resources :person, only: [:index, :show], controller: 'people'

  get '/people/:id/index', to: 'people#show'
  get '/person/:id/index', to: 'people#show'
end
