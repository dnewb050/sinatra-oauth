require 'sinatra/base'
require 'sinatra/activerecord'
require 'dotenv'
require 'httparty'
Dotenv.load

class Shop < ActiveRecord::Base
  validates :shopify_domain, presence: true, uniqueness: true
end

class Application < Sinatra::Base
  APP_URL = "localhost:3000"
  API_KEY = ENV['API_KEY']
  API_SECRET = ENV['API_SECRET']
  SCOPES = "read_orders,read_products"

  DOMAIN_REGEX = %r{^[\w-]+.myshopify.com$}

  def initialize
    super
  end

  get '/install' do
    shopify_domain = request.params['shop']
    nonce = rand(1...100).to_s

    shop = Shop.find_or_create_by!( shopify_domain: shopify_domain )
    shop.update!(nonce: nonce)

    redirect_uri = "http://#{APP_URL}/auth/shopify/callback"
    options = ""

    install_url = "https://#{shopify_domain}/admin/oauth/authorize?client_id=#{API_KEY}&scope=#{SCOPES}&redirect_uri=#{redirect_uri}&state=#{nonce}&grant_options[]=#{options}"

    redirect install_url
  end

  get '/auth/shopify/callback' do
    code = request.params['code']
    hmac = request.params['hmac']
    request_nonce = request.params['state']
    shopify_domain = request.params['shop']

    shop = Shop.find_by(shopify_domain: shopify_domain)
    nonce = shop&.nonce

    return [403, "Authentication failed. Nonce was invalid"] unless nonce == request_nonce
    return [403, "Authentication failed. Shopify Domain was invalid"] unless validate_shop_domain(shopify_domain)
    return [403, "Authentication failed. HMAC was invalid"] unless validate_hmac(request)

    request_body = {
      client_id: API_KEY,
      client_secret: API_SECRET,
      code: code,
    }

    response = HTTParty.post(
      "https://#{shopify_domain}/admin/oauth/access_token",
      body: request_body
    )

    if response.code == 200
      shop.update!(access_token: response["access_token"])
      "It worked!"
    else
      "it didn't work!"
    end
  end

  helpers do
    def validate_shop_domain(shopify_domain)
      !!shopify_domain[DOMAIN_REGEX]
    end

    def validate_hmac(request)
      param_array = []
      message = request.params.reject { |key, _| key == "hmac"}.map { |key, value| "#{key}=#{value}" }.join('&')

      digest = OpenSSL::HMAC.hexdigest('SHA256', API_SECRET, message)

      request.params['hmac'] == digest
    end
  end
end
