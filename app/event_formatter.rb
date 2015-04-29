class EventFormatter
  attr_reader :ical

  def initialize(ical_data)
    @ical = ical_data
  end

  def set_ical_to_v2
    @ical.version = '2.0'
  end

  def remove_events_beginning_after(time)
    @ical.events.reject! do |event|
      event.dtstart < time
    end
  end

  def set_event_lengths(length)
    @ical.events.each do |event|
      event.dtend = event.dtstart + length
    end
  end

  def join_consecutive_events
    grouped_events = @ical.events.group_by do |event|
      s = event.dtstart
      "#{s.year}-#{s.month}-#{s.day}"
    end
    grouped_events.each_value do |grouped_events|
      sorted = grouped_events.sort {|a, b| b.dtstart <=> a.dtstart}
      last_start = nil
      sorted.each do |event|
        # Only join events which overlap
        if last_start.present? && last_start < event.dtend
          event.dtend = last_start
        end
        last_start = event.dtstart
      end
    end
  end

  def set_timezone(timezone_name)
    tz = TZInfo::Timezone.get timezone_name
    timezone = tz.ical_timezone DateTime.new(2002, 1, 1, 1, 1)
    @ical.add_timezone(timezone)
    @ical.events.each do |e|
      e.dtstart = Icalendar::Values::DateTime.new(e.dtstart, 'tzid' => timezone_name)
      e.dtend = Icalendar::Values::DateTime.new(e.dtend, 'tzid' => timezone_name)
    end
  end
end
