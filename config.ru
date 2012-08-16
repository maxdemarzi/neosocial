# -*- encoding: utf-8 -*-
$:.unshift File.dirname(__FILE__)

ENV['RACK_ENV'] ||= 'development'

require 'lib/neosocial'
require 'neosocial_app'
require 'sidekiq/web'

map '/' do
  run App
end

map '/sidekiq' do
  run Sidekiq::Web
end