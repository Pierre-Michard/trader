json.extract! user, :id, :paymium_secret, :paymium_token, :kraken_secret, :kraken_token, :created_at, :updated_at
json.url user_url(user, format: :json)
