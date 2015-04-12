while read i; do 
    lat=`curl "http://mesowest.utah.edu/cgi-bin/droman/side_mesodyn.cgi?stn=$i&unit=0&time=LOCAL&year1=&month1=&day1=0&hour1=00&hours=24&past=0&graph=&order=1" | grep LATIT | awk '{print $2}'`
    long=`curl "http://mesowest.utah.edu/cgi-bin/droman/side_mesodyn.cgi?stn=$i&unit=0&time=LOCAL&year1=&month1=&day1=0&hour1=00&hours=24&past=0&graph=&order=1" | grep LONGIT | awk '{print $2}'`
    elev=`curl "http://mesowest.utah.edu/cgi-bin/droman/side_mesodyn.cgi?stn=$i&unit=0&time=LOCAL&year1=&month1=&day1=0&hour1=00&hours=24&past=0&graph=&order=1" | grep ELEV | awk '{print $2}'`
    echo $i   $lat   $long    $elev
sleep $(((RANDOM % 5) + 3))
done < sdgestations.txt 