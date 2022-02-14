require 'spec_helper'

module SchedulePreciseTesting
  def diff(unit, incr, method, count)
    diff = Time.now.to_i.send(method, incr * count)
    Time.at(diff)
  end

  def day(method, count)
    diff(:hour, 3600 * 24, method, count)
  end

  def hour(method, count)
    diff(:hour, 3600, method, count)
  end

  def min(method, count)
    diff(:min, 60, method, count)
  end
end

describe Puppet::Type.type(:schedule_precise) do
  include SchedulePreciseTesting

  before :each do
    Puppet[:ignoreschedules] = false

    @schedule_precise = Puppet::Type.type(:schedule_precise).new(:name => "testing")
  end

  describe Puppet::Type.type(:schedule_precise) do
    it "should apply to device" do
      expect(@schedule_precise).to be_appliable_to_device
    end

    it "should apply to host" do
      expect(@schedule_precise).to be_appliable_to_host
    end

    it "should default to :distance for period-matching" do
      expect(@schedule_precise[:periodmatch]).to eq(:distance)
    end

    it "should default to a :repeat of 1" do
      expect(@schedule_precise[:repeat]).to eq(1)
    end

    it "should never match when the period is :never" do
      @schedule_precise[:period] = :never
      expect(@schedule_precise).to_not be_match
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when producing default schedules" do
    %w{hourly daily weekly monthly quarterly never}.each do |period|
      period = period.to_sym
      it "should produce a #{period} schedule with the period set appropriately" do
        schedules = Puppet::Type.type(:schedule_precise).mkdefaultschedules
        expect(schedules.find { |s| s[:name] == period.to_s and s[:period] == period }).to be_instance_of(Puppet::Type.type(:schedule_precise))
      end
    end

    it "should not produce default schedules when default_schedules is false"  do
      Puppet[:default_schedules] = false
      schedules = Puppet::Type.type(:schedule_precise).mkdefaultschedules
      expect(schedules).to be_empty
    end

    it "should produce a schedule named puppet with a period of hourly and a repeat of 2" do
      schedules = Puppet::Type.type(:schedule_precise).mkdefaultschedules
      expect(schedules.find { |s|
        s[:name] == "puppet" and s[:period] == :hourly and s[:repeat] == 2
      }).to be_instance_of(Puppet::Type.type(:schedule_precise))
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching ranges" do
    before do
      allow(Time).to receive(:now).and_return(Time.local(2011, "may", 23, 11, 0, 0))
    end

    it "should match when the start time is before the current time and the end time is after the current time" do
      @schedule_precise[:range] = "10:59:50 - 11:00:10"
      expect(@schedule_precise).to be_match
    end

    it "should not match when the start time is after the current time" do
      @schedule_precise[:range] = "11:00:05 - 11:00:10"
      expect(@schedule_precise).to_not be_match
    end

    it "should not match when the end time is previous to the current time" do
      @schedule_precise[:range] = "10:59:50 - 10:59:55"
      expect(@schedule_precise).to_not be_match
    end

    it "should not match the current time fails between an array of ranges" do
      @schedule_precise[:range] = ["4-6", "20-23"]
      expect(@schedule_precise).to_not be_match
    end

    it "should match the lower array of ranges" do
      @schedule_precise[:range] = ["9-11", "14-16"]
      expect(@schedule_precise).to be_match
    end

    it "should match the upper array of ranges" do
      @schedule_precise[:range] = ["11:30 - 6", "11-12"]
      expect(@schedule_precise).to be_match
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching ranges with abbreviated time specifications" do
    before do
      allow(Time).to receive(:now).and_return(Time.local(2011, "may", 23, 11, 45, 59))
    end

    it "should match when just an hour is specified" do
      @schedule_precise[:range] = "11-12"
      expect(@schedule_precise).to be_match
    end

    it "should not match when the ending hour is the current hour" do
      @schedule_precise[:range] = "10-11"
      expect(@schedule_precise).to_not be_match
    end

    it "should not match when the ending minute is the current minute" do
      @schedule_precise[:range] = "10:00 - 11:45"
      expect(@schedule_precise).to_not be_match
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching ranges with abbreviated time specifications, edge cases part 1" do
    before do
      allow(Time).to receive(:now).and_return(Time.local(2011, "may", 23, 11, 00, 00))
    end

    it "should match when the current time is the start of the range using hours" do
      @schedule_precise[:range] = "11 - 12"
      expect(@schedule_precise).to be_match
    end

    it "should match when the current time is the end of the range using hours" do
      @schedule_precise[:range] = "10 - 11"
      expect(@schedule_precise).to be_match
    end

    it "should match when the current time is the start of the range using hours and minutes" do
      @schedule_precise[:range] = "11:00 - 12:00"
      expect(@schedule_precise).to be_match
    end

    it "should match when the current time is the end of the range using hours and minutes" do
      @schedule_precise[:range] = "10:00 - 11:00"
      expect(@schedule_precise).to be_match
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching ranges with abbreviated time specifications, edge cases part 2" do
    before do
      allow(Time).to receive(:now).and_return(Time.local(2011, "may", 23, 11, 00, 01))
    end

    it "should match when the current time is just past the start of the range using hours" do
      @schedule_precise[:range] = "11 - 12"
      expect(@schedule_precise).to be_match
    end

    it "should not match when the current time is just past the end of the range using hours" do
      @schedule_precise[:range] = "10 - 11"
      expect(@schedule_precise).to_not be_match
    end

    it "should match when the current time is just past the start of the range using hours and minutes" do
      @schedule_precise[:range] = "11:00 - 12:00"
      expect(@schedule_precise).to be_match
    end

    it "should not match when the current time is just past the end of the range using hours and minutes" do
      @schedule_precise[:range] = "10:00 - 11:00"
      expect(@schedule_precise).to_not be_match
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching ranges with abbreviated time specifications, edge cases part 3" do
    before do
      allow(Time).to receive(:now).and_return(Time.local(2011, "may", 23, 10, 59, 59))
    end

    it "should not match when the current time is just before the start of the range using hours" do
      @schedule_precise[:range] = "11 - 12"
      expect(@schedule_precise).to_not be_match
    end

    it "should match when the current time is just before the end of the range using hours" do
      @schedule_precise[:range] = "10 - 11"
      expect(@schedule_precise).to be_match
    end

    it "should not match when the current time is just before the start of the range using hours and minutes" do
      @schedule_precise[:range] = "11:00 - 12:00"
      expect(@schedule_precise).to_not be_match
    end

    it "should match when the current time is just before the end of the range using hours and minutes" do
      @schedule_precise[:range] = "10:00 - 11:00"
      expect(@schedule_precise).to be_match
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching ranges spanning days, day 1" do
    before do
      # Test with the current time at a month's end boundary to ensure we are
      # advancing the day properly when we push the ending limit out a day.
      # For example, adding 1 to 31 would throw an error instead of advancing
      # the date.
      allow(Time).to receive(:now).and_return(Time.local(2011, "mar", 31, 22, 30, 0))
    end

    it "should match when the start time is before current time and the end time is the following day" do
      @schedule_precise[:range] = "22:00:00 - 02:00:00"
      expect(@schedule_precise).to be_match
    end

    it "should not match when the current time is outside the range" do
      @schedule_precise[:range] = "23:30:00 - 21:00:00"
      expect(@schedule_precise).to_not be_match
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching ranges spanning days, day 2" do
    before do
      # Test with the current time at a month's end boundary to ensure we are
      # advancing the day properly when we push the ending limit out a day.
      # For example, adding 1 to 31 would throw an error instead of advancing
      # the date.
      allow(Time).to receive(:now).and_return(Time.local(2011, "mar", 31, 1, 30, 0))
    end

    it "should match when the start time is the day before the current time and the end time is after the current time" do
      @schedule_precise[:range] = "22:00:00 - 02:00:00"
      expect(@schedule_precise).to be_match
    end

    it "should not match when the start time is after the current time" do
      @schedule_precise[:range] = "02:00:00 - 00:30:00"
      expect(@schedule_precise).to_not be_match
    end

    it "should not match when the end time is before the current time" do
      @schedule_precise[:range] = "22:00:00 - 01:00:00"
      expect(@schedule_precise).to_not be_match
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching hourly by distance" do
    before do
      @schedule_precise[:period] = :hourly
      @schedule_precise[:periodmatch] = :distance

      allow(Time).to receive(:now).and_return(Time.local(2011, "may", 23, 11, 0, 0))
    end

    it "should match when the previous time was an hour ago" do
      expect(@schedule_precise).to be_match(hour("-", 1))
    end

    it "should not match when the previous time was now" do
      expect(@schedule_precise).to_not be_match(Time.now)
    end

    it "should not match when the previous time was 59 minutes ago" do
      expect(@schedule_precise).to_not be_match(min("-", 59))
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching daily by distance" do
    before do
      @schedule_precise[:period] = :daily
      @schedule_precise[:periodmatch] = :distance

      allow(Time).to receive(:now).and_return(Time.local(2011, "may", 23, 11, 0, 0))
    end

    it "should match when the previous time was one day ago" do
      expect(@schedule_precise).to be_match(day("-", 1))
    end

    it "should not match when the previous time is now" do
      expect(@schedule_precise).to_not be_match(Time.now)
    end

    it "should not match when the previous time was 23 hours ago" do
      expect(@schedule_precise).to_not be_match(hour("-", 23))
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching weekly by distance" do
    before do
      @schedule_precise[:period] = :weekly
      @schedule_precise[:periodmatch] = :distance

      allow(Time).to receive(:now).and_return(Time.local(2011, "may", 23, 11, 0, 0))
    end

    it "should match when the previous time was seven days ago" do
      expect(@schedule_precise).to be_match(day("-", 7))
    end

    it "should not match when the previous time was now" do
      expect(@schedule_precise).to_not be_match(Time.now)
    end

    it "should not match when the previous time was six days ago" do
      expect(@schedule_precise).to_not be_match(day("-", 6))
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching monthly by distance" do
    before do
      @schedule_precise[:period] = :monthly
      @schedule_precise[:periodmatch] = :distance

      allow(Time).to receive(:now).and_return(Time.local(2011, "may", 23, 11, 0, 0))
    end

    it "should match when the previous time was 32 days ago" do
      expect(@schedule_precise).to be_match(day("-", 32))
    end

    it "should not match when the previous time was now" do
      expect(@schedule_precise).to_not be_match(Time.now)
    end

    it "should not match when the previous time was 27 days ago" do
      expect(@schedule_precise).to_not be_match(day("-", 27))
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching hourly by number" do
    before do
      @schedule_precise[:period] = :hourly
      @schedule_precise[:periodmatch] = :number
    end

    it "should match if the times are one minute apart and the current minute is 0" do
      current = Time.utc(2008, 1, 1, 0, 0, 0)
      previous = Time.utc(2007, 12, 31, 23, 59, 0)

      allow(Time).to receive(:now).and_return(current)
      expect(@schedule_precise).to be_match(previous)
    end

    it "should not match if the times are 59 minutes apart and the current minute is 59" do
      current = Time.utc(2009, 2, 1, 12, 59, 0)
      previous = Time.utc(2009, 2, 1, 12, 0, 0)

      allow(Time).to receive(:now).and_return(current)
      expect(@schedule_precise).to_not be_match(previous)
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching daily by number" do
    before do
      @schedule_precise[:period] = :daily
      @schedule_precise[:periodmatch] = :number
    end

    it "should match if the times are one minute apart and the current minute and hour are 0" do
      current = Time.utc(2010, "nov", 7, 0, 0, 0)

      # Now set the previous time to one minute before that
      previous = current - 60

      allow(Time).to receive(:now).and_return(current)
      expect(@schedule_precise).to be_match(previous)
    end

    it "should not match if the times are 23 hours and 58 minutes apart and the current hour is 23 and the current minute is 59" do

      # Reset the previous time to 00:00:00
      previous = Time.utc(2010, "nov", 7, 0, 0, 0)

      # Set the current time to 23:59
      now = previous + (23 * 3600) + (59 * 60)

      allow(Time).to receive(:now).and_return(now)
      expect(@schedule_precise).to_not be_match(previous)
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching weekly by number" do
    before do
      @schedule_precise[:period] = :weekly
      @schedule_precise[:periodmatch] = :number
    end

    it "should match if the previous time is prior to the most recent Sunday" do
      now = Time.utc(2010, "nov", 11, 0, 0, 0) # Thursday
      allow(Time).to receive(:now).and_return(now)
      previous = Time.utc(2010, "nov", 6, 23, 59, 59) # Sat

      expect(@schedule_precise).to be_match(previous)
    end

    it "should not match if the previous time is after the most recent Saturday" do
      now = Time.utc(2010, "nov", 11, 0, 0, 0) # Thursday
      allow(Time).to receive(:now).and_return(now)
      previous = Time.utc(2010, "nov", 7, 0, 0, 0) # Sunday

      expect(@schedule_precise).to_not be_match(previous)
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching monthly by number" do
    before do
      @schedule_precise[:period] = :monthly
      @schedule_precise[:periodmatch] = :number
    end

    it "should match when the previous time is prior to the first day of this month" do
      now = Time.utc(2010, "nov", 8, 00, 59, 59)
      allow(Time).to receive(:now).and_return(now)
      previous = Time.utc(2010, "oct", 31, 23, 59, 59)

      expect(@schedule_precise).to be_match(previous)
    end

    it "should not match when the previous time is after the last day of last month" do
      now = Time.utc(2010, "nov", 8, 00, 59, 59)
      allow(Time).to receive(:now).and_return(now)
      previous = Time.utc(2010, "nov", 1, 0, 0, 0)

      expect(@schedule_precise).to_not be_match(previous)
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching quarterly by number" do
    before do
      @schedule_precise[:period] = :quarterly
      @schedule_precise[:periodmatch] = :number
    end

    it "should match when the previous time is greater than three months" do
      now = Time.utc(2010, "dec", 4, 01, 59, 59)
      allow(Time).to receive(:now).and_return(now)
      previous = Time.utc(2010, "sep", 3, 00, 59, 59)

      expect(@schedule_precise).to be_match(previous)
    end

    it "should not match when the previous time is within three months" do
      now = Time.utc(2010, "nov", 7, 00, 59, 59)
      allow(Time).to receive(:now).and_return(now)
      previous = Time.utc(2010, "sep", 8, 0, 0, 0)

      expect(@schedule_precise).to_not be_match(previous)
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching with a repeat greater than one" do
    before do
      @schedule_precise[:period] = :daily
      @schedule_precise[:repeat] = 2

      allow(Time).to receive(:now).and_return(Time.local(2011, "may", 23, 11, 0, 0))
    end

    it "should fail if the periodmatch is 'number'" do
      @schedule_precise[:periodmatch] = :number
      expect {
        @schedule_precise[:repeat] = 2
      }.to raise_error(Puppet::Error)
    end

    it "should match if the previous run was further away than the distance divided by the repeat" do
      previous = Time.now - (3600 * 13)
      expect(@schedule_precise).to be_match(previous)
    end

    it "should not match if the previous run was closer than the distance divided by the repeat" do
      previous = Time.now - (3600 * 11)
      expect(@schedule_precise).to_not be_match(previous)
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching days of the week" do
    before do
      # 2011-05-23 is a Monday
      allow(Time).to receive(:now).and_return(Time.local(2011, "may", 23, 11, 0, 0))
    end

    it "should raise an error if the weekday is 'Someday'" do
      expect { @schedule_precise[:weekday] = "Someday" }.to raise_error(Puppet::Error)
    end

    it "should raise an error if the weekday is '7'" do
      expect { @schedule_precise[:weekday] = "7" }.to raise_error(Puppet::Error)
    end

    it "should accept all full weekday names as valid values" do
      expect { @schedule_precise[:weekday] = ['Sunday', 'Monday', 'Tuesday', 'Wednesday',
          'Thursday', 'Friday', 'Saturday'] }.not_to raise_error
    end

    it "should accept all short weekday names as valid values" do
      expect { @schedule_precise[:weekday] = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu',
          'Fri', 'Sat'] }.not_to raise_error
    end

    it "should accept all integers 0-6 as valid values" do
      expect {@schedule_precise[:weekday] = [0, 1, 2, 3, 4,
      5, 6] }.not_to raise_error
    end

    it "should match if the weekday is 'Monday'" do
      @schedule_precise[:weekday] = "Monday"
      expect(@schedule_precise.match?).to be_truthy
    end

    it "should match if the weekday is 'Mon'" do
      @schedule_precise[:weekday] = "Mon"
      expect(@schedule_precise.match?).to be_truthy
    end

    it "should match if the weekday is '1'" do
      @schedule_precise[:weekday] = "1"
      expect(@schedule_precise.match?).to be_truthy
    end

    it "should match if weekday is 1" do
      @schedule_precise[:weekday] = 1
      expect(@schedule_precise).to be_match
    end

    it "should not match if the weekday is Tuesday" do
      @schedule_precise[:weekday] = "Tuesday"
      expect(@schedule_precise).not_to be_match
    end

    it "should match if weekday is ['Sun', 'Mon']" do
      @schedule_precise[:weekday] = ["Sun", "Mon"]
      expect(@schedule_precise.match?).to be_truthy
    end

    it "should not match if weekday is ['Sun', 'Tue']" do
      @schedule_precise[:weekday] = ["Sun", "Tue"]
      expect(@schedule_precise).not_to be_match
    end

    it "should match if the weekday is 'Monday'" do
      @schedule_precise[:weekday] = "Monday"
      expect(@schedule_precise.match?).to be_truthy
    end

    it "should match if the weekday is 'Mon'" do
      @schedule_precise[:weekday] = "Mon"
      expect(@schedule_precise.match?).to be_truthy
    end

    it "should match if the weekday is '1'" do
      @schedule_precise[:weekday] = "1"
      expect(@schedule_precise.match?).to be_truthy
    end

    it "should not match if the weekday is Tuesday" do
      @schedule_precise[:weekday] = "Tuesday"
      expect(@schedule_precise).not_to be_match
    end

    it "should match if weekday is ['Sun', 'Mon']" do
      @schedule_precise[:weekday] = ["Sun", "Mon"]
      expect(@schedule_precise.match?).to be_truthy
    end
  end

  it "should raise an error if the weekday is an int higher than 6" do
    expect { @schedule_precise[:weekday] = 7 }.to raise_error(Puppet::ResourceError, /7 is not a valid day of the week/)
  end

  describe Puppet::Type.type(:schedule_precise), "when matching days of week and ranges spanning days, day 1" do
    before do
      # Test with ranges and days-of-week both set. 2011-03-31 was a Thursday.
      allow(Time).to receive(:now).and_return(Time.local(2011, "mar", 31, 22, 30, 0))
    end

    it "should match when the range and day of week matches" do
      @schedule_precise[:range] = "22:00:00 - 02:00:00"
      @schedule_precise[:weekday] = "Thursday"
      expect(@schedule_precise).to be_match
    end

    it "should not match when the range doesn't match even if the day-of-week matches" do
      @schedule_precise[:range] = "23:30:00 - 21:00:00"
      @schedule_precise[:weekday] = "Thursday"
      expect(@schedule_precise).to_not be_match
    end

    it "should not match when day-of-week doesn't match even if the range matches (1 day later)" do
      @schedule_precise[:range] = "22:00:00 - 01:00:00"
      @schedule_precise[:weekday] = "Friday"
      expect(@schedule_precise).to_not be_match
    end

    it "should not match when day-of-week doesn't match even if the range matches (1 day earlier)" do
      @schedule_precise[:range] = "22:00:00 - 01:00:00"
      @schedule_precise[:weekday] = "Wednesday"
      expect(@schedule_precise).to_not be_match
    end
  end

  describe Puppet::Type.type(:schedule_precise), "when matching days of week and ranges spanning days, day 2" do
    before do
      # 2011-03-31 was a Thursday. As the end-time of a day spanning match, that means
      # we need to match on Wednesday.
      allow(Time).to receive(:now).and_return(Time.local(2011, "mar", 31, 1, 30, 0))
    end

    it "should match when the range matches and the day of week should match" do
      @schedule_precise[:range] = "22:00:00 - 02:00:00"
      @schedule_precise[:weekday] = "Wednesday"
      expect(@schedule_precise).to be_match
    end

    it "should not match when the range does not match and the day of week should match" do
      @schedule_precise[:range] = "22:00:00 - 01:00:00"
      @schedule_precise[:weekday] = "Thursday"
      expect(@schedule_precise).to_not be_match
    end

    it "should not match when the range matches but the day-of-week does not (1 day later)" do
      @schedule_precise[:range] = "22:00:00 - 02:00:00"
      @schedule_precise[:weekday] = "Thursday"
      expect(@schedule_precise).to_not be_match
    end

    it "should not match when the range matches but the day-of-week does not (1 day later)" do
      @schedule_precise[:range] = "22:00:00 - 02:00:00"
      @schedule_precise[:weekday] = "Tuesday"
      expect(@schedule_precise).to_not be_match
    end
  end
end
