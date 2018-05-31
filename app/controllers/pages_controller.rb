class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :linkedin]

  def home
    @linkedin_url = "https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=#{ENV['LINKEDIN_CLIENT_ID']}&redirect_uri=http://localhost:3000/linkedin_callback&state=987654321&scope=r_basicprofile r_emailaddress"
  end

  def linkedin
    headers = {
      "Host" => "www.linkedin.com",
      "Content-Type" => "application/x-www-form-urlencoded"
    }

    body = {
      "grant_type" => "authorization_code",
      "code" => params[:code],
      "redirect_uri" => "http://localhost:3000/linkedin_callback",
      "client_id" => "#{ENV['LINKEDIN_CLIENT_ID']}",
      "client_secret" => "#{ENV['LINKEDIN_CLIENT_ID']}"
    }

    uri = URI.parse("https://www.linkedin.com/oauth/v2/accessToken")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = body.to_query
    response = http.request(request)
    results = JSON.parse(response.body)


    uri = URI.parse("https://api.linkedin.com/v1/people/~:(id,first-name,last-name,picture-url,public-profile-url,email-address)?format=json")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri, {
      "Host" => "api.linkedin.com",
      "Connection" => "Keep-Alive",
      "Authorization" => "Bearer #{results["access_token"]}"
    })

    response = http.request(request)
    results = JSON.parse(response.body)

    # What you need to do is add a field to the user table like 'linkedin_id'
    # So that when someone arrives here, instead of just always creating a new user
    # we try to find them from the database first, because maybe they already created a 
    # an account with US via linkedin

    # FIND BY LINKED ID
    # user = User.find_by(linkedin_id: results["id"])

    if user.nil?
      # OR CREATE A NEW USER
      user = User.create(email: results["emailAddress"], linkedin_id: results["id"], password: Devise.friendly_token[0,20])
    end

    sign_in(user, scope: :user)

    redirect_to root_path
  end
end
