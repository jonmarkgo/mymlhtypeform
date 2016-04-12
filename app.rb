require 'sinatra'
require "sinatra/multi_route"
require 'httparty'
require 'json'

class MyMLHTypeform < Sinatra::Base
  register Sinatra::MultiRoute

  # Config
  client_id = ENV['MYMLH_APP_ID']
  client_secret = ENV['MYMLH_SECRET']
  typeform_url = ENV['TYPEFORM_URL']

  # Helpers

  def fetch_user(access_token)
    base_url = "https://my.mlh.io/api/v1/user"
    qs = URI.encode_www_form({'access_token' => access_token})

    # Tokens don't expire, but users can reset them, so best to do some error
    # handling here too.
    HTTParty.get("#{base_url}?#{qs}")
  end

  # Routes

  get '/' do
    "<a href='/auth/mlh'>Login with MLH</a>"
  end

  get '/auth/mlh' do  
    # Step 1: Request an Authorization Code from My MLH by directing a user to
    # your app's authorize page.

    base_url = "https://my.mlh.io/oauth/authorize"
    qs = URI.encode_www_form(
      'client_id' => client_id,
      'redirect_uri' => request.url + "/callback",
      'response_type' => 'code'
    )

    redirect "#{base_url}?#{qs}"
  end

  route :get, :post, '/auth/mlh/callback' do
    # Step 2: Assuming the user clicked authorize, we should get an Authorization
    # Code which we can now exchange for an access token.
    base_url = "https://my.mlh.io/oauth/token"
    code = params[:code]

    headers = { 'Content-Type' => 'application/json' }
    body = {
      'client_id' => client_id,
      'client_secret' => client_secret,
      'code' => code,
      'grant_type' => 'authorization_code',
      'redirect_uri' => request.url
    }.to_json

    unless code
      # If somehow we got here without a code, tell the user it's an invalid request
      halt 400  , "Error: No code found"
    end

    resp = HTTParty.post( base_url, body: body, headers: headers )
    puts resp
    if resp.code == 200 # Success response
      # Step 3: Now we should have an access token which we can use to get the
      # current user's profile information.  In a production app you would
      # create a user and save it to your database at this point.

      user = fetch_user(resp['access_token'])
    #  puts user['data']['id']
      mymlh_id = user['data']['id']
      email = user['data']['email']
      first_name = user['data']['first_name']
      last_name = user['data']['last_name']
      graduation = user['data']['graduation']
      major = user['data']['major']
      shirt_size = user['data']['shirt_size']
      dietary_restrictions = user['data']['dietary_restrictions']
      special_needs = user['data']['special_needs']
      dob = user['data']['date_of_birth']
      gender = user['data']['gender']
      phone = user['data']['phone_number']
      school = user['data']['school']['name']
      url = URI.escape("#{typeform_url}?mymlh_id=#{mymlh_id}&email=#{email}&first_name=#{first_name}&last_name=#{last_name}&graduation=#{graduation}&major=#{major}&shirt_size=#{shirt_size}&dietary_restrictions=#{dietary_restrictions}&special_needs=#{special_needs}&date_of_birth=#{dob}&gender=#{gender}&phone_number=#{phone}&school=#{school}&source=mymlh")
      redirect url
     # return user['data']
    else
      # Really you should have better error handling
      halt 500  , "Error: Internal Server Error"
    end
  end
end