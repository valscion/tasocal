require 'httparty'

class RefereeMixpanelWorker
  include Sidekiq::Worker

  def perform(referee_id, options)
    # Sidekiq translates all hash keys to normal strings, but we don't care
    options = options.with_indifferent_access
    mixpanel_token = options[:mixpanel_token]
    mixpanel_options = options[:mixpanel_options]
    people_options = mixpanel_options.slice(:distinct_id, :ip)

    result = HTTParty.get("http://www.spluusimaa.fi/taso/ottelulista.php?tuomari=#{referee_id}")
    regex_name = result.response.body.match(%r{<h1>([^<]+)</h1>}) if result.response.code == 200
    optional_params = {}
    unless regex_name.nil?
      full_name = regex_name[1]
      last_name, first_name = full_name.split(" ", 2)
      if first_name.nil? || last_name.nil?
        optional_params['$name'] = full_name
      else
        optional_params['$first_name'] = first_name
        optional_params['$last_name'] = last_name
      end
    end

    time_ms = if mixpanel_options[:properties].present?
      mseconds = mixpanel_options[:properties][:time].to_f * 1000.0
      mseconds > 1 ? mseconds.to_i : nil
    end
    optional_params['$time'] = time_ms if time_ms

    people_options.merge(optional_params: optional_params)

    once_options = people_options.merge({
      properties: {
        'First Calendar Feed Fetch' => Time.now,
      }
    })
    increment_options = people_options.merge({
      properties: {
        'Feed Results Fetched' => 1
      }
    })

    MixpanelPeopleWorker.perform_async(mixpanel_token, :set_once, once_options)
    MixpanelPeopleWorker.perform_async(mixpanel_token, :increment, increment_options)
    MixpanelWorker.perform_async(mixpanel_token, mixpanel_options)
  end
end
