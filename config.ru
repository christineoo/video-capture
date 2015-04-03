require 'bundler'
require 'rubygems'

Bundler.require

require './server.rb'
run Sinatra::Application
