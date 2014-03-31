TwitterCrow::Application.routes.draw do
  
  #AJAX PATHS
  get 'crawl_user_tweets' => "ajax#crawl_user_tweets"
  get 'crawl_nearby_tweets' => "ajax#crawl_nearby_tweets"
  get 'run_geoclustering' => "ajax#run_geoclustering"
  get 'run_language_modeling' => "ajax#run_language_modeling"
  get 'worker_status' => "ajax#worker_status"
  get 'get_coordinates' => "ajax#get_coordinates"
  get 'get_clustered_tweets' => "ajax#get_clustered_tweets"
  get 'get_tweets' => "ajax#get_tweets"
  get 'get_tweets_with_geo' => "ajax#get_tweets_with_geo"
  
  post 'set_current_location' => "ajax#set_current_location"
  get 'get_current_location' => "ajax#get_current_location"
  post 'set_current_cluster' => "ajax#set_current_cluster"
  
  get 'reset_session' => "ajax#reset_session"
  
  get 'generation_explanation' => "ajax#generation_explanation"
  
  get 'generate_next_tweet' => 'ajax#generate_next_tweet'
  
  root "dashboard#index"
  get 'about' => "dashboard#about"
  
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

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

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
