$:.unshift File.dirname(__FILE__)

require 'bundler'
Bundler.require(:default, (ENV["RACK_ENV"]|| 'development').to_sym)

Sidekiq.configure_server do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'], :size => 10}
end

Sidekiq.configure_client do |config|
  config.redis = { :url => ENV['REDISTOGO_URL'] , :size => 10}
end

Koala.http_service.http_options = {
    :ssl => { :ca_file => "./cacert.pem" }
}

$neo_server = Neography::Rest.new

require 'neosocial/models/user'
require 'neosocial/models/like'

require 'neosocial/jobs/import_facebook_profile'
require 'neosocial/jobs/import_friends'
require 'neosocial/jobs/import_mutual_friends'