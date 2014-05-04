#!/usr/bin/env ruby
require 'ri_cal'
require 'httparty'
require 'pry'
require './spl_uusimaa'

APPLICATION_NAME = 'vesq-spluusimaa-ical'

class EventFormatter
  def initialize(ical_data)
    @ical = ical_data
  end

  def remove_events_beginning_after(time)
    @ical.events.reject! do |event|
      event.dtstart < time
    end
  end
end

client = SplUusimaa.new('account@example.com', 'password')

puts 'Logging in...'
client.login!
puts 'Logged in!'

puts 'Fetching matches...'
matches_raw = client.matches
puts 'Matches fetched!'

matches = EventFormatter.new(matches_raw)
matches.remove_events_beginning_after(DateTime.now)

binding.pry
