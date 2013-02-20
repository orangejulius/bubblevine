require 'instagram'
require 'json'
require 'sinatra'
require 'open-uri'

enable :sessions

CALLBACK_URL = "http://localhost:4567/oauth/callback"

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
	puts "session user id is " + session[:user_id]
	Instagram.create_subscription(object: 'user', aspect: 'media', callback_url: 'http://bubblevine.herokuapp.com/realtime_callback', object_id: session[:user_id],client_id: ENV['INSTAGRAM_CLIENT_ID'], verify_token: 'foo')
end

get '/realtime_callback' do
	params['hub.challenge']
end

post '/realtime_callback' do
	params['hub.challenge']
end
