#coding:utf-8
require 'date'
require 'time'

############################################################################################################
# HOW TO USE                                                                                               #
############################################################################################################

=begin
  require 'cc'
  CC.use 'chrono' # immediately when loading this file

  timing = Time.now
  puts [2023, 10, 10, 12, 30, 45]=="2023-10-10 12:30:45".time,
      [2023, 10, 10, 12, 30, 45]=="2023-10-10T12:30:45".time,
      [timing.year, timing.month, timing.day, timing.hour, timing.min, timing.sec]==(Time.now).strftime("%Y-%m-%d %H:%M:%S").time,
      ["12", "30", "45"]=="123045".tag_to_numtime,
      "12:30:45"=="123045".tag_to_time,
      ["2023", "10", "10"]=="20231010".tag_to_numdate,
      "2023-10-10"=="20231010".tag_to_date,
      ["2023", "10", "10", "12", "30", "45"]=="20231010123045".tag_to_number,
      "2023-10-10 12:30:45"=="20231010123045".tag_to_datetime,
      "Tuesday"=="2023-10-10".weekday,
      "Tuesday"==Time.new(2023, 10, 10).weekday,
      "Tuesday"==DateTime.new(2023, 10, 10).weekday,
      "2023-10-10"==Time.new(2023, 10, 10).date,
      "2023-10-10"==DateTime.new(2023, 10, 10).date,
      "12:30:45"==Time.new(2023, 10, 10, 12, 30, 45).time,
      "12:30:45"==DateTime.new(2023, 10, 10, 12, 30, 45).time,
      "2023-10-10 12:30:45"==Time.new(2023, 10, 10, 12, 30, 45).form,
      "2023-10-10 12:30:45"==DateTime.new(2023, 10, 10, 12, 30, 45).form,
      "20231010123045"==Time.new(2023, 10, 10, 12, 30, 45).tag,
      "20231010123045"==DateTime.new(2023, 10, 10, 12, 30, 45).tag,
      Time.new(2023, 10, 10, 12, 30, 45)==Time.form("2023-10-10 12:30:45"),
      DateTime.new(2023, 10, 10, 12, 30, 45)==DateTime.form("2023-10-10 12:30:45"),
      Time.new.strftime('%Y%m%d%H%M%S')==Time.tag,
      DateTime.new.strftime('%Y%m%d%H%M%S')==DateTime.tag,
      1==1.sec,
      60==1.min,
      3600==1.hour
=end

class String
  def time
    # date = /[0-9]+\-[0-9]+\-[0-9]+/.match(self)
    # time = /[0-9]+\:[0-9]+\:[0-9]+/.match(self)
    # year, month, day = date.to_s.split("-")
    # hour, minute, second = time.to_s.split(":")
    itime = Time.parse(self)
    return itime.year||Time.now.year, itime.month||Time.now.month, 
    itime.day||Time.now.day,itime.hour||Time.now.hour, 
    itime.min||Time.now.min, itime.sec||Time.now.sec
  end
  
  def tag_to_numtime
    return [] unless self.size==6
    return self.unpack("a2a2a2")
  end
  
  def tag_to_time
    return nil unless self.size==6
    return self.unpack("a2a2a2").join(":")
  end
  
  def tag_to_numdate
    return [] unless self.size==8
    return self.unpack("a4a2a2")
  end
  
  def tag_to_date
    return nil unless self.size==8
    return self.unpack("a4a2a2").join("-")
  end
  
  def tag_to_number
    return [] unless self.size==14
    return self[0..7].tag_to_numdate+self[-6..-1].tag_to_numtime
  end
  
  def tag_to_datetime
    return nil unless self.size==14
    return self[0..7].tag_to_date+" "+self[-6..-1].tag_to_time
  end
  
  def weekday
    Time.form(self).weekday
  end
end

class Time
  def weekday
    self.strftime('%A')
  end

  def date
    self.strftime("%Y-%m-%d")
  end
  
  def time
    self.strftime("%H:%M:%S")
  end

  def form
    self.strftime("%Y-%m-%d %H:%M:%S")
  end

  def tag
    self.strftime("%Y%m%d%H%M%S")
  end
  
  def self.form string
    Time.new *string.time
  end
  
  def self.tag
    Time.new.strftime('%Y%m%d%H%M%S')
  end
end

class DateTime
  def weekday
    self.strftime('%A')
  end

  def date
    self.strftime("%Y-%m-%d")
  end
  
  def time
    self.strftime("%H:%M:%S")
  end

  def form
    self.strftime("%Y-%m-%d %H:%M:%S")
  end

  def tag
    self.strftime("%Y%m%d%H%M%S")
  end
  
  def self.form string
    DateTime.new *string.time
  end
  
  def self.tag
    DateTime.new.strftime('%Y%m%d%H%M%S')
  end
end

class Integer
  def min
    sec = self*60
  end
  
  def hour
    sec = self*3600
  end
  
  def sec
    sec = self
  end
end
