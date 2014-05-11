require 'mixpanel-ruby'

class MixpanelPeopleWorker
  include Sidekiq::Worker

  def perform(token, action_or_options, options = {})
    if action_or_options.is_a? Hash
      action = :set
      options = action_or_options
    else
      action = action_or_options.to_sym
    end

    # Sidekiq translates all hash keys to normal strings, but we don't care
    options = options.with_indifferent_access
    client = Mixpanel::Tracker.new(token)
    client.people.send(
      action,
      options[:distinct_id],
      options[:properties],
      options[:ip],
      options[:optional_params]
    )
  end
end
