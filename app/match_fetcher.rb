class MatchFetcher
  include HTTParty
  APPLICATION_NAME = 'vesq-spluusimaa-ical'

  base_uri 'http://www.spluusimaa.fi/taso'

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

    # spluusimaa.fi returns invalid iCal format, fix it to be importable.
    raw_ical = response.body.gsub(%r{^DT(START|END);}, 'DT\1:')

    # The encoding is said to be ISO-8859-1 but it is actually UTF-8
    raw_ical.encode!('utf-8', 'utf-8')
  end

  def ical_matches(raw_ical)
    Icalendar.parse(raw_ical).first
  end

  def fix_descriptions(ical_data)
    ical_data.events.each do |event|
      descr = event.description.join.gsub(%r{<a.+href=.+otteluid=(\d+).+</a></a>}, '\1')
      event.description = descr
    end
    ical_data
  end
end
