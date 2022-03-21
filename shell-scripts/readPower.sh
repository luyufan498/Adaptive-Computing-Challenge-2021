i=0
while(true)
do
    cat /sys/class/hwmon/hwmon1/power1_input
    let i++
    if [ $i -eq 10000 ]; then 
        break;
    fi
    sleep 0.5
done