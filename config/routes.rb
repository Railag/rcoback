Rails.application.routes.draw do

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope '/group', controller: 'group' do
    get '/get', action: 'get'
    post '/fetch', action: 'fetch'
    post '/fetch_users', action: 'fetch_users'
    post '/fetch_messages', action: 'fetch_messages'
    post '/add_user', action: 'add_user'
    post '/', action: 'create'
    put '/:id', action: 'update'
    delete '/:id', action: 'destroy'
  end

  scope '/user', controller: 'user' do
    get '/get', action: 'get'
    post '/login', action: 'login'
    post '/startup_login', action: 'startup_login'
    post '/', action: 'create'
    put '/:id', action: 'update'
    delete '/:id', action: 'destroy'
  end

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'
end
