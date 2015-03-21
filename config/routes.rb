Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  root to: 'players#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  resources :status, only: :index
  resources :players, only: :index

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  namespace :admin do
    resources :preferences
    resources :callbacks, as: :server_callbacks, controller: :callbacks do
      collection do
        patch :reset_all_cooldown
      end
      member do
        patch :toggle_enabled
        get :execute_command
        patch :reset_cooldown
      end
    end
    
    resources :sessions, only: [:new, :create]
    delete 'session' => 'sessions#destroy', as: :destroy_session
    
    get 'config/server_properties' => 'config#show_server_properties'
    mount Resque::Server, at: "/resque"
  end
end
