require 'json'
require 'sinatra'
require 'open-uri'

@@token = ENV['INSTAGRAM_TOKEN']

def get_photo_url
	url = 'https://api.instagram.com/v1/users/self/feed?client_id=c42c61f4ed8d48149c22aa51deacf4f1&access_token='+@@token
	response = open(url).read
	response_json = JSON.parse(response)
	response_json['data'][0]['images']['standard_resolution']['url']
end

get '/photo' do
	get_photo_url
end
