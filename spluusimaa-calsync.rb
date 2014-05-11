#!/usr/bin/env ruby
require 'active_support'
require 'active_support/core_ext'
require 'icalendar'
require 'icalendar/tzinfo'
require 'httparty'

require './app/match_fetcher'
require './app/event_formatter'

require 'sinatra'

configure do
  set :mixpanel, begin
    if settings.production? || (settings.development? && ENV['MIXPANEL_ENABLED'])
      ENV['MIXPANEL_TOKEN']
    end
  end
end

get '/' do
  erb :index
end

get '/cal' do
  @referee_id = if params[:referee_id].present?
    id_as_number = params[:referee_id].to_i
    (id_as_number > 0) ? id_as_number : nil
  end
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
  matches.set_timezone("Europe/Helsinki")

  matches.ical.to_ical
end
