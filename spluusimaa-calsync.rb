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

get '/cal' do
  @referee_id = params[:referee_id].to_i if params.has_key? :referee_id
  erb :cal
end

get '/cal/:referee_id' do |referee_id|
  client = MatchFetcher.new(referee_id)

  puts "Fetching matches for ##{referee_id}..."
  matches_raw = client.matches
  puts "Matches fetched for ##{referee_id}!"

  matches = EventFormatter.new(matches_raw)
  matches.remove_events_beginning_after(DateTime.now)
  matches.set_event_lengths(2.hours)
  matches.join_consecutive_events

  matches.ical.to_ical
end
