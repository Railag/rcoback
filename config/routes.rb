Rails.application.routes.draw do

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope '/group', controller: 'group' do
    get '/get', action: 'get'
    post '/fetch', action: 'fetch'
    post '/fetch_users', action: 'fetch_users'
    post '/fetch_messages', action: 'fetch_messages'
    post '/send_message', action: 'send_message'
    post '/add_invite_user', action: 'add_invite_user'
    post '/add_user', action: 'add_user'
    post '/remove_user', action: 'remove_user'
    post '/start_call', action: 'start_call'
    post '/invite_to_call', action: 'invite_to_call'
    post '/', action: 'create'
    put '/:id', action: 'update'
    delete '/:id', action: 'destroy'
  end

  scope '/user', controller: 'user' do
    get '/get', action: 'get'
    post '/login', action: 'login'
    post '/startup_login', action: 'startup_login'
    post '/fcm_token', action: 'fcm_token'
    post '/send_pns_to_group', action: 'send_pns_to_group'
    post '/send_pns_to_everyone', action: 'send_pns_to_everyone'
    post '/', action: 'create'
    put '/:id', action: 'update'
    delete '/:id', action: 'destroy'
  end

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'
end
