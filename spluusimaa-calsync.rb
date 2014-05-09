#!/usr/bin/env ruby
require 'active_support'
require 'active_support/core_ext'
require 'icalendar'
require 'icalendar/tzinfo'
require 'httparty'

require './app/match_fetcher'
require './app/event_formatter'

require 'sinatra'

get '/' do
  erb :index
end

get '/cal/:email/:password' do |email, password|
  client = MatchFetcher.new(email, password)

  logger.info "Logging in #{email}..."
  client.login!
  puts "Logged in #{email}!"

  puts 'Fetching matches...'
  matches_raw = client.matches
  puts 'Matches fetched!'

  matches = EventFormatter.new(matches_raw)
  matches.remove_events_beginning_after(DateTime.now)
  matches.set_event_lengths(2.hours)
  matches.join_consecutive_events

  matches.ical.to_ical
end
