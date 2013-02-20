require 'instagram'
require 'json'
require 'sinatra'
require 'pusher'
require 'open-uri'

enable :sessions

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
  session[:access_token] = response.access_token
	session[:user_id] = response.user.id
  redirect "/feed"
end

get "/feed" do
  client = Instagram.client(:access_token => session[:access_token])
  user = client.user

  html = "<h1>#{user.username}'s recent photos</h1>"
  for media_item in client.user_recent_media
    html << "<img src='#{media_item.images.thumbnail.url}'>"
  end
  html
end

def get_photo_url
	url = 'https://api.instagram.com/v1/users/self/feed?client_id=c42c61f4ed8d48149c22aa51deacf4f1&access_token='+session[:access_token]
	response = open(url).read
	response_json = JSON.parse(response)
	response_json['data'][0]['images']['standard_resolution']['url']
end

get '/photo' do
	get_photo_url
end

get '/create_realtime_subscription' do
	callback_url = ENV['BASE_URL'] + 'realtime_callback'
	response = Instagram.create_subscription(object: 'user', aspect: 'media', callback_url: callback_url, object_id: session[:user_id],client_id: ENV['INSTAGRAM_CLIENT_ID'], verify_token: 'foo')
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
	Pusher[user_id].trigger('new-photo', {'message' => 'new photo posted'})
end
