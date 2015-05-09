#!/usr/bin/env ruby
require 'active_support'
require 'active_support/core_ext'
require 'icalendar'
require 'icalendar/tzinfo'
require 'httparty'

require './app/match_fetcher'
require './app/event_formatter'
require './app/workers'
