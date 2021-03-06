#!/usr/bin/env ruby
require './boot_files.rb'

require 'sinatra'

configure do
  set :mixpanel, begin
    if settings.production? || (settings.development? && ENV['MIXPANEL_ENABLED'])
      ENV['MIXPANEL_TOKEN']
    end
  end

  Sidekiq.configure_server do |config|
    config.redis = { :size => 5, :namespace => 'tasocal' }
  end

  Sidekiq.configure_client do |config|
    config.redis = { :size => 1, :namespace => 'tasocal' }
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
  matches.set_ical_to_v2
  matches.remove_events_beginning_after(DateTime.now)
  matches.set_event_lengths(2.hours)
  matches.join_consecutive_events
  matches.set_timezone("Europe/Helsinki")

  if settings.mixpanel?
    uri = URI.parse(request.referrer) unless request.referrer.nil?
    properties = {
      'User Agent' => request.user_agent,
      'time' => Time.now.to_i,
      'referee_id' => referee_id
    }
    unless uri.nil?
      properties['$referrer'] = request.referrer
      properties['$referring_domain'] = uri.host
    end
    RefereeMixpanelWorker.perform_async(referee_id, {
      mixpanel_token: settings.mixpanel,
      mixpanel_options: {
        distinct_id: "referee-#{referee_id}",
        event: "Fetched Calendar Feed",
        ip: request.ip,
        properties: properties
      }
    })
  end

  headers 'Content-Type' => 'text/plain'

  matches.ical.to_ical
end
