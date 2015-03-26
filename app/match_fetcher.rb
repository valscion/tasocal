class MatchFetcher
  include HTTParty
  APPLICATION_NAME = 'vesq-spluusimaa-ical'

  base_uri 'http://taso.palloliitto.fi/taso'

  def initialize(referee_id)
    @referee_id = referee_id
  end

  def matches
    @matches ||= begin
      raw_ical = if ENV['USE_CACHE']
        fetch_matches_with_cache
      else
        fetch_matches
      end
      tmp = ical_matches(raw_ical)
      fix_descriptions(tmp)
    end
  end

  def fetch_matches_with_cache
    if File.exists?("tmp/tmp.ics")
      File.read("tmp/tmp.ics")
    else
      fetched = fetch_matches
      File.write("tmp/tmp.ics", fetched)
      fetched
    end
  end

  def fetch_matches
    response = self.class.get('/tehtavakalenteri.php', query: {
      tuomari: @referee_id
    })
  end

  def ical_matches(raw_ical)
    Icalendar.parse(raw_ical).first
  end

  def fix_descriptions(ical_data)
    ical_data.events.each do |event|
      orig_descr_str = event.description.respond_to?(:join) ? event.description.join : event.description
      descr = orig_descr_str.gsub(%r{<a.+href=.+otteluid=(\d+).+</a>}, '\1')
      event.description = descr
    end
    ical_data
  end
end
