#!/usr/bin/env ruby
# frozen_string_literal: true

#
# Simple sinatra app to receive and display callbacks
#
require 'sinatra'

set :port, 9230

post '/callback' do
  puts "Received callback"
  pp params
end
