require 'httparty'

class RefereeMixpanelWorker
  include Sidekiq::Worker

  def perform(referee_id, options)
    # Sidekiq translates all hash keys to normal strings, but we don't care
    options = options.with_indifferent_access
    mixpanel_token = options[:mixpanel_token]
    mixpanel_options = options[:mixpanel_options]

    basic_options = mixpanel_options
      .slice(:distinct_id, :ip)
      .merge(optional_params: optional_params(mixpanel_options[:properties]))

    once_properties = { 'First Calendar Feed Fetch' => Time.now.to_i }
    once_properties.merge!(fetch_name_hash(referee_id))
    once_options = basic_options.merge({
      properties: once_properties
    })

    increment_options = basic_options.merge({
      properties: {
        'Feed Results Fetched' => 1
      }
    })

    MixpanelPeopleWorker.perform_async(mixpanel_token, :set_once, once_options)
    MixpanelPeopleWorker.perform_async(mixpanel_token, :increment, increment_options)
    MixpanelWorker.perform_async(mixpanel_token, mixpanel_options)
  end

  private

  def fetch_name_hash(referee_id)
    person = {}
    result = HTTParty.get("http://www.spluusimaa.fi/taso/ottelulista.php?tuomari=#{referee_id}")
    regex_name = result.response.body.match(%r{<h1>([^<]+)</h1>}) if result.response.code == "200"
    if regex_name.nil?
      raise "Failed to fetch name for ##{referee_id}"
    else
      full_name = regex_name[1]
      last_name, first_name = full_name.split(" ", 2)
      if first_name.nil? || last_name.nil?
        person['$name'] = full_name
      else
        person['$first_name'] = first_name
        person['$last_name'] = last_name
      end
    end
    person
  end

  def optional_params(properties)
    result = {}
    time_ms = unless properties.nil?
      mseconds = properties[:time].to_f * 1000.0
      mseconds > 1 ? mseconds.to_i : nil
    end
    result['$time'] = time_ms if time_ms
    result
  end
end
