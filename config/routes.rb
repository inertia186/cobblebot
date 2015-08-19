require 'api_constraints'

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
  resources :topics, only: :index
  get 'server-icon.png' => 'resources#server_icon', as: :server_icon

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
        get :gist_callback
      end
    end
    resources :links, except: [:new, :create, :edit, :update]
    resources :messages, except: [:new, :create, :edit, :update]
    resources :ips, only: [:index]
    resources :players, except: [:new, :create, :edit, :update] do
      member do
        patch :toggle_may_autolink
      end
      resources :links, except: [:new, :create, :edit, :update]
      resources :messages, except: [:new, :create, :edit, :update]
    end
    
    resources :sessions, only: [:new, :create]
    delete 'session' => 'sessions#destroy', as: :destroy_session
    
    get 'config/server_properties' => 'config#show_server_properties'
    get 'config/console' => 'config#console'
    mount Resque::Server, at: "/resque"
  end
  
  namespace :api, defaults: {format: 'json'} do
    scope module: :v1, constraints: ApiConstraints.new(version: 1, default: 1) do
      resource :session, only: %w(create update destroy)
      resources :players, only: %w(index show)
      resources :messages, only: %w(index show)
    end
  end
end
