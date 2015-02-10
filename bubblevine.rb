require 'instagram'
require 'json'
require 'redis'
require 'sinatra'
require "sinatra/content_for"
require 'slim'
require 'pusher'
require 'open-uri'

enable :sessions

INSTAGRAM_CALLBACK_URL = ENV['BASE_URL'] + 'instagram/oauth/callback'

Instagram.configure do |config|
  config.client_id = ENV['INSTAGRAM_CLIENT_ID']
  config.client_secret = ENV['INSTAGRAM_CLIENT_SECRET']
end

Pusher.app_id = ENV['PUSHER_APP_ID']
Pusher.key = ENV['PUSHER_KEY']
Pusher.secret = ENV['PUSHER_SECRET']

# user facing routes
get "/" do
	slim :index
end

get '/example' do
	@user_id = session[:user_id]
	@base_url = ENV['BASE_URL']
	slim :example
end

get '/photo' do
	get_photo_url(params[:user_id])
end

# oath routes
get "/instagram/oauth/connect" do
  redirect Instagram.authorize_url(redirect_uri: INSTAGRAM_CALLBACK_URL)
end

get "/instagram/oauth/callback" do
  response = Instagram.get_access_token(params[:code], redirect_uri: INSTAGRAM_CALLBACK_URL)

	redis.set(response.user.id, response.access_token)
	create_realtime_subscription(response.user.id)
	session[:user_id] = response.user.id
  redirect "/example"
end

# realtime callback routes
#this is used to verify the realtime subscription during creation
get '/instagram/realtime_callback' do
	params['hub.challenge']
end

#this is POSTed to by Instagram on realtime events
post '/instagram/realtime_callback' do
	data = JSON.parse(request.body.read.to_s)
	user_id = data[0]['object_id']
	photo = get_photo_url(user_id)
	Pusher[user_id].trigger('new-photo', {'message' => photo})
end

# helper method to get the photo url to use
def get_photo_url(user_id)
	access_token = redis.get(user_id)
	client = Instagram.client(access_token: access_token)
	client.user_recent_media(user_id)[0].images.standard_resolution.url.sub('http://', 'https://')
end

# helper method to create a new realtime subscription
def create_realtime_subscription(user_id)
	callback_url = ENV['BASE_URL'] + 'instagram/realtime_callback'
	response = Instagram.create_subscription(object: 'user', aspect: 'media',
                                           callback_url: callback_url,
                                           object_id: user_id,
                                           client_id: ENV['INSTAGRAM_CLIENT_ID'],
                                           verify_token: 'foo')
end

# helper method to get a redis object
def redis
  if ENV['REDISTOGO_URL']
    uri = URI.parse(ENV["REDISTOGO_URL"])
    Redis.new(host: uri.host, port: uri.port, password: uri.password)
  else
    Redis.new
  end
end

