#!/usr/bin/env ruby
require 'ri_cal'
require 'httparty'
require 'pry'
require './spl_uusimaa'

APPLICATION_NAME = 'vesq-spluusimaa-ical'

client = SplUusimaa.new('account@example.com', 'password')

puts 'Logging in...'
client.login!
puts 'Logged in!'

puts 'Fetching matches...'
matches = client.matches
puts 'Matches fetched!'

binding.pry
