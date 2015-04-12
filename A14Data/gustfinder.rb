require 'open-uri'
require 'nokogiri'

stdate = "10/22/07 2:06 AM"
stname = "VLCC1"

stdts = Array.new()
stdts[0] = DateTime.strptime(stdate,'%m/%d/%y %H:%M %p')
stdts[1] = stdts[0] + 1

maxgust = 0.0
stdts.each do |sd|
  yr = sd.year
  mo = sd.month
  dy = sd.day
  hr = sd.hour
  weather_url="http://mesowest.utah.edu/cgi-bin/droman/meso_table_mesodyn.cgi?stn=#{stname}&unit=0&time=LOCAL&year1=#{yr}&month1=#{mo}&day1=#{dy}&hour1=#{hr}&hours=24&past=1&order=1"
  weatherdoc = Nokogiri::HTML(open(weather_url))
  puts weatherdoc.css('title')
  maxgust_text = weatherdoc.css('tr')[5].css('td')[4].text
  puts "max 24 hr gust prior to #{mo}/#{dy}/#{yr} #{hr}:00 is #{maxgust_text}\n"
  gust = maxgust_text.split()[0].to_f
  if gust > maxgust then maxgust = gust end
end 
puts "Maximum 48 hour gust is #{maxgust}"

