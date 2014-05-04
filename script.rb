#!/usr/bin/env ruby
require 'active_support'
require 'active_support/core_ext'
require 'ri_cal'
require 'httparty'
require 'pry'
require './spl_uusimaa'

APPLICATION_NAME = 'vesq-spluusimaa-ical'

class EventFormatter
  attr_reader :ical

  def initialize(ical_data)
    @ical = ical_data
  end

  def remove_events_beginning_after(time)
    @ical.events.reject! do |event|
      event.dtstart < time
    end
  end

  def set_event_lengths(length)
    @ical.events.each do |event|
      event.dtend = event.dtstart + length
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
matches.set_event_lengths(2.hours)

binding.pry
