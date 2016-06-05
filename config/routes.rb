Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  scope '/user', controller: 'user' do
    get '/get', action: 'get'
    get '/', action: 'index'
    get '/:id', action: 'show'
    post '/', action: 'create'
    put '/:id', action: 'update'
    delete '/:id', action: 'destroy'
  end

  # Serve websocket cable requests in-process
  # mount ActionCable.server => '/cable'
end
