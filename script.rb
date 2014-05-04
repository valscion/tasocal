#!/usr/bin/env ruby
require 'ri_cal'
require 'httparty'
require 'pry'

APPLICATION_NAME = 'vesq-spluusimaa-ical'

class SplUusimaa
  include HTTParty

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
end

client = SplUusimaa.new('account@example.com', 'password')
client.login!
