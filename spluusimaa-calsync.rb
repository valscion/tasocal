#!/usr/bin/env ruby
require 'active_support'
require 'active_support/core_ext'
require 'ri_cal'
require 'httparty'
require 'pry'

require './app/spl_uusimaa'
require './app/event_formatter'

client = SplUusimaa.new('account@example.com', 'password')

puts 'Logging in...'
client.login!
puts 'Logged in!'

puts 'Fetching matches...'
matches_raw = client.matches
puts 'Matches fetched!'

matches = EventFormatter.new(matches_raw)
matches.remove_events_beginning_after(DateTime.now)
matches.set_event_lengths(2.hours)
matches.join_consecutive_events

binding.pry
