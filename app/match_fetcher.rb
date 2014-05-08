class MatchFetcher
  include HTTParty
  APPLICATION_NAME = 'vesq-spluusimaa-ical'

  class LoginFailed < StandardError; end

  base_uri 'http://www.spluusimaa.fi/taso'

  def initialize(user, password)
    @auth = { user: user, password: password }
    @referee_id = nil
  end

  def login
    response = self.class.get('/login.php')
    @headers = {
      'Cookie' => response.headers['Set-Cookie'],
      'User-Agent' => APPLICATION_NAME,
    }
    response = self.class.post('/login.php', {
      body: {
        tunnus: @auth[:user],
        salasana: @auth[:password]
      },
      headers: @headers
    })

    # spluusimaa redirects users to index page after successful location with
    # a weird JS code
    logged_in = response.body == %{<script>document.location='/index.php'</script>}

    if logged_in
      response = self.class.get('/tuomari.php', { headers: @headers })
      find_id = response.body.match(%r{<input name=tuomari type=hidden value= (\d+)>})
      raise 'Could not find referee ID!' unless find_id
      @referee_id = find_id[1].to_i
      raise 'spluusimaa.fi API changed!' unless @referee_id.to_s == find_id[1]
      true
    else
      false
    end
  end

  def login!
    raise LoginFailed unless login
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
    if File.exists?("tmp.ics")
      File.read("tmp.ics")
    else
      fetched = fetch_matches
      File.write("tmp.ics", fetched)
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
    RiCal.parse_string(raw_ical).first
  end

  def fix_descriptions(ical_data)
    ical_data.events.each do |event|
      descr = event.description.gsub(%r{<a.+href=.+otteluid=(\d+).+</a></a>}, '\1')
      event.description = descr
    end
    ical_data
  end
end
