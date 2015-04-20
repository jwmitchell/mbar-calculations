require 'open-uri'
require 'nokogiri'

DEBUG=2

class MesoMax
  # Class to find the max/min of past 24 hour weather data from a mesowest-tracked station. Can be extended to any weather variable by finding the correct 'tr'/'td' path in the html page.

  def initialize (mmdate, station)
    raise "ERROR - Need DateTime class" unless mmdate.class == DateTime
    @yr = mmdate.year
    @mo = mmdate.month
    @dy = mmdate.day
    @hr = mmdate.hour
    @station = station
    @fail = true

    if DEBUG > 1 then puts "Station: #{@station}  #{@yr}/#{@mo}/#{@dy} #{@hr}:00" end
    weather_url="http://mesowest.utah.edu/cgi-bin/droman/meso_table_mesodyn.cgi?stn=#{@station}&unit=0&time=LOCAL&year1=#{@yr}&month1=#{@mo}&day1=#{@dy}&hour1=#{@hr}&hours=24&past=1&order=1"
    if DEBUG > 1 then puts weather_url end
    @weatherdoc = Nokogiri::HTML(open(weather_url))
    if DEBUG > 0 then STDERR.puts @weatherdoc.css('title') end
    if @weatherdoc.css('title').text =~ /WBB\sWeather/ then raise "ERROR - Default station WBB returned. Station #{station} passed in." end
    
  end
  
  def dont_fail_on_empty
    @fail=false
  end

  def fail_on_empty
    @fail=true
  end

  def max_gust
    
    if @station[0] == 'K' then 
      idx=5
      gustfactor = 1.6
    else
      idx=5
      if @weatherdoc.css('tr')[idx].css('td')[0].text =~ /Speed/ then idx=6 end
      gustfactor = 1.0
    end
    
    maxgust_text = @weatherdoc.css('tr')[idx].css('td')[4].text
    if DEBUG > 1 then STDERR.puts "index = #{idx} " + @weatherdoc.css('tr')[idx].css('td')[0].text end
    if DEBUG > 0 then STDERR.puts "max 24 hr gust prior to #{@mo}/#{@dy}/#{@yr} #{@hr}:00 is #{maxgust_text}\n" end
    max_gust = (maxgust_text.split()[0].to_f) * gustfactor
    
    rescue 
    if !@fail then 
      max_gust = "N/A" 
    else
      raise "ERROR - max_gust unable to parse web data"
    end
    
  end
  
end
