ENV['REDIS_URL'] = ENV['REDISTOGO_URL'] unless ENV['REDISTOGO_URL'].nil?

require 'sidekiq/web'
map '/sidekiq' do
  use Rack::Auth::Basic, "Protected Area" do |username, password|
    require 'digest/sha2'
    hashed = Digest::SHA256.hexdigest(username + ':' + password)
    hashed == ENV['SIDEKIQ_AUTH']
  end

  Sidekiq.configure_client do |config|
    config.redis = { :namespace => 'tasocal' }
  end
  Sidekiq.configure_server do |config|
    config.redis = { :namespace => 'tasocal' }
  end

  run Sidekiq::Web
end

require './tasocal'
run Sinatra::Application
