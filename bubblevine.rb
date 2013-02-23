require 'instagram'
require 'json'
require 'redis'
require 'sinatra'
require "sinatra/content_for"
require 'slim'
require 'pusher'
require 'open-uri'

enable :sessions

if ENV['REDISTOGO_URL']
	uri = URI.parse(ENV["REDISTOGO_URL"])
	@@redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
else
	@@redis = Redis.new
end

CALLBACK_URL = ENV['BASE_URL']+'oauth/callback'

Instagram.configure do |config|
  config.client_id = ENV['INSTAGRAM_CLIENT_ID']
  config.client_secret = ENV['INSTAGRAM_CLIENT_SECRET']
end

get "/" do
  '<a href="/oauth/connect">Connect with Instagram</a>'
end

get "/oauth/connect" do
  redirect Instagram.authorize_url(:redirect_uri => CALLBACK_URL)
end

get "/oauth/callback" do
  response = Instagram.get_access_token(params[:code], :redirect_uri => CALLBACK_URL)

	@@redis.set(response.user.id, response.access_token)
	session[:user_id] = response.user.id
  redirect "/example"
end

get '/example' do
	@user_id = session[:user_id]
	slim :example
end

def get_photo_url(user_id)
	access_token = @@redis.get(user_id)
	url = 'https://api.instagram.com/v1/users/self/feed?client_id=c42c61f4ed8d48149c22aa51deacf4f1&access_token='+access_token
	response = open(url).read
	response_json = JSON.parse(response)
	response_json['data'][0]['images']['standard_resolution']['url']
end

get '/photo' do
	get_photo_url(params[:user_id])
end

get '/create_realtime_subscription' do
	callback_url = ENV['BASE_URL'] + 'realtime_callback'
	response = Instagram.create_subscription(object: 'user', aspect: 'media', callback_url: callback_url, object_id: params[:user_id], client_id: ENV['INSTAGRAM_CLIENT_ID'], verify_token: 'foo')
	"success"
end

#this is used to verify the realtime subscription
get '/realtime_callback' do
	params['hub.challenge']
end

#this is POSTed to by Instagram on realtime events
post '/realtime_callback' do
	data = JSON.parse( request.body.read.to_s )
	user_id = data[0]['object_id']
	photo = get_photo_url(user_id)
	Pusher[user_id].trigger('new-photo', {'message' => photo})
end
