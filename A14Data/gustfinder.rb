require 'open-uri'
require 'nokogiri'
require 'roo'

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

    weather_url="http://mesowest.utah.edu/cgi-bin/droman/meso_table_mesodyn.cgi?stn=#{@station}&unit=0&time=LOCAL&year1=#{@yr}&month1=#{@mo}&day1=#{@dy}&hour1=#{@hr}&hours=24&past=1&order=1"
    if DEBUG > 1 then puts weather_url end
    @weatherdoc = Nokogiri::HTML(open(weather_url))
    if DEBUG > 0 then STDERR.puts @weatherdoc.css('title') end
    if @weatherdoc.css('title').text =~ /WBB\sWeather/ then raise "ERROR - Default station WBB returned. Station #{station} passed in." end
    
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
if DEBUG>0 then puts "Maximum 48 hour gust is #{maxgust}" end

excel_data_file = Roo::Excelx.new('MGRA-DR3-66-Mbar.xlsx')

mxg_file = File.new('FWO_max_gusts.dat','w')

for rw in (2..166) do

  stdts[0] = excel_data_file.cell(rw,'B',"FireWeatherOutages")
  stdts[1] = stdts[0] + 1
  stname = excel_data_file.cell(rw,'I',"FireWeatherOutages")
  maxgust = 0.0
  stdts.each do |sd|
    mesodat = MesoMax.new(sd,stname)
    gust = mesodat.max_gust
    if gust > maxgust then maxgust = gust end
  end 
  if DEBUG>0 then puts "Maximum 48 hour gust is #{maxgust}" end
  mxg_file.puts(maxgust)
  sleep(3+Random.rand(4))
  
end

mxg_file.close

