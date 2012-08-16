class App < Sinatra::Base

  use Rack::Session::Cookie , :secret => (ENV['SESSION_SECRET'] || "82e042cd6fde2bf1764f777236db799e")

  fields = ["id", "email-address", "first-name", "last-name", "headline", "industry", "picture-url", "public-profile-url", "location", "skills"]

  use OmniAuth::Builder do
    provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_SECRET'], :scope => 'user_likes, user_location, friends_likes, friends_location', :client_options => {:ssl => {:ca_file => "./cacert.pem"}}
  end

  Dir.glob(File.dirname(__FILE__) + '/helpers/*', &method(:require))
  helpers App::Helpers

  # Homepage
  get '/' do
    if current_user.nil?
      haml :index, :layout => :layout
    else
      redirect to("/user/#{current_user["data"]["uid"]}")
    end
  end

  # Authentication
  ['get', 'post'].each do |method|
    send(method, "/auth/:provider/callback") do
      user = User.create_with_omniauth(env['omniauth.auth'])
      session[:uid] = user["data"]["uid"]

      redirect to(session[:redirect_url] || "/user/#{session[:uid]}")
      session[:redirect_url] = nil
    end
  end

  get '/auth/failure/?' do
    raise 'auth error'
  end

  get '/logout/?' do
    session.clear
    redirect to('/')
  end

  # Users
  get '/user/:id' do
    @user = user(params[:id])
    @friends_count = User.friends_count(@user)
    @likes_count = User.likes_count(@user)
    haml :'user/show'
  end

  get '/user/:id/friends' do
    @user = user(params[:id])
    @friends = User.friends(@user)
    haml :'user/index'
  end

  get '/user/:id/likes' do
    @user = user(params[:id])
    @likes = User.likes(@user)
    haml :'like/index'
  end

  # Likes
  get '/like/:id' do
    @like = Like.get_by_id(params[:id])
    @like_users = Like.users(@like)
    haml :'like/show'
  end

end
