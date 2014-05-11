require 'mixpanel-ruby'

class MixpanelWorker
  include Sidekiq::Worker

  # Tracks an event to Mixpanel
  #
  # === Arguments
  # * <tt>token</tt> - The mixpanel token associated with the request
  # * <tt>options</tt> - A hash for the tracked event, see below
  #
  # ==== Options
  # * <tt>:distinct_id => 'id123'</tt> - The unique identifier used to identify
  #   and track the user between session
  # * <tt>:event => 'My Event'</tt> - The event name to track to Mixpanel
  #   (e.g. "Fetched Calendar Feed")
  # * <tt>:properties => {}</tt> - A hash of options which will be assigned to
  #   the tracked event. There can be a maximum of 255 different properties for
  #   a single event.
  #   https://mixpanel.com/help/questions/articles/what-is-a-data-point
  # * <tt>:ip => nil</tt> - The IP of the user who sent the event. If this is
  #   not set, the IP of the server will be used (which is not good).
  def perform(token, options = {})
    # Sidekiq translates all hash keys to normal strings, but we don't care
    options = options.with_indifferent_access
    client = Mixpanel::Tracker.new(token)
    client.track(
      options[:distinct_id],
      options[:event],
      options[:properties],
      options[:ip],
    )
  end
end
