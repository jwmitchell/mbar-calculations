require 'open-uri'
require 'nokogiri'

DEBUG=2

class MesoMax
  # Class to find the max/min of past 24 hour weather data from a mesowest-tracked station. Can be extended to any weather variable by finding the correct 'tr'/'td' path in the html page.

  def initialize (mmdate, station)
    raise "ERROR - Need DateTime date class" unless mmdate.class == DateTime
    @yr = mmdate.year
    @mo = mmdate.month
    @dy = mmdate.day
    @hr = mmdate.hour
    @station = station

    weather_url="http://mesowest.utah.edu/cgi-bin/droman/meso_table_mesodyn.cgi?stn=#{@station}&unit=0&time=LOCAL&year1=#{@yr}&month1=#{@mo}&day1=#{@dy}&hour1=#{@hr}&hours=24&past=1&order=1"
    @weatherdoc = Nokogiri::HTML(open(weather_url))
    if DEBUG > 1 then STDERR.puts @weatherdoc.css('title') end
    if @weatherdoc.css('title').text =~ /WBB\sWeather/ then raise "ERROR - Default station WBB returned. Station #{station} passed in." end
    
  end
  
  def max_gust
    maxgust_text = @weatherdoc.css('tr')[5].css('td')[4].text
    if DEBUG > 1 then STDERR.puts "max 24 hr gust prior to #{@mo}/#{@dy}/#{@yr} #{@hr}:00 is #{maxgust_text}\n" end
    max_gust = maxgust_text.split()[0].to_f
  end

end

##################

stdate = "10/22/07 2:06 AM"
stname = "VLCC1"

stdts = Array.new()
stdts[0] = DateTime.strptime(stdate,'%m/%d/%y %H:%M %p')
stdts[1] = stdts[0] + 1

maxgust = 0.0
stdts.each do |sd|
  mesodat = MesoMax.new(sd,stname)
  gust = mesodat.max_gust
  if gust > maxgust then maxgust = gust end
end 
puts "Maximum 48 hour gust is #{maxgust}"

