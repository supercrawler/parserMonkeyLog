#!/bin/sh

clear
adb logcat -c
usage() 
{
  echo "  "
  echo "  "  
  echo "Usage: $0 packagename event_num img_count devices"
  echo "\t packagename: eg. com.dolphin.browser.cn"
  echo "\t event_num: eg. 10000"
  echo "\t img_count: eg. 10"
  echo "\t devices 38334C1B4C5F00EC"
  echo "\t eg:"
  echo "\t $0 com.dolphin.browser.cn 10000 10 38334C1B4C5F00EC"
  echo "  "
  echo "  "

}

if [ $# -ne 4 ]; then
  usage
  exit 1
fi

#redefine input parameters
packagename="$1"
event_num=$2
img_count=$3
devices=$4
if [[ $((event_num/1000/img_count)) -eq 0 ]]; then
   echo "event_num must larger than 1000*$img_count"
   usage
   exit 1
fi

#define filter keyword
BEGIN_PATTERN=":Monkey:"
SUCCESS_PATTERN="Monkey finished"
EVENTS_INJECT_PATTERN="Events injected:"
CRASH_PATTERN="// CRASH:"
APP_NOT_RESPONDING_PATTERN="// NOT RESPONDING:"
SEND_EVENT_PATTERN="// Sending event"

find_keyword()
{
	if [ $# -ne 2 ]; then
		echo "Usage $0 line pattern "
		exit 1
	fi
	mm=`awk 'BEGIN {print index("'"$1"'", "'"$2"'")}'`
	if [ $mm -gt 0 ]; then
		echo 1
		return;		
	fi
	echo 0
}

screenshots()
{
    if [ $# -ne 1 ]; then
        echo "Usage $0 imgname"
        exit 1
    fi
    imgname=`echo ${1}.png`
    echo $imgname
    ./screenshot.jar -s $devices $imgname
}

#define variables
crash_flag=0
respond_flag=0
flag=0

#define image path and filename
path="screenshots"
if [ ! -d $path ]; then
    mkdir $path
fi
cur_date=`date '+%Y%m%d_%H%M%S'`
filename=`echo $path/$cur_date`

pre_num=0
cur_num=0
img_num=0
div=$((event_num/100/img_count))
echo "div:"$div
adb shell monkey -p $packagename -v $event_num | while read line
do 
        
	mm=`find_keyword "$line" "$BEGIN_PATTERN"`
	if [ $mm -gt 0 ]; then
		echo $line
		continue
	fi

	mm=`find_keyword "$line" "$SEND_EVENT_PATTERN"`
	if [ $mm -gt 0 ]; then
		cur_num=`echo "$line" | grep -o "[0-9]*"`
		echo "cur:"$cur_num
		echo "pre:"$pre_num
		if [ $cur_num -ne $pre_num ]; then
			echo $line
			pre_num=$cur_num
			#shortcut img
			if [ $((img_num%div)) -eq 0 ]; then
				echo "===>screenshots: "$img_num
                screenshots "${filename}_${img_num}"
			fi
			img_num=$((img_num+1))
		fi
		continue
	fi

	crash_flag=`find_keyword "$line" "$CRASH_PATTERN"`
	respond_flag=`find_keyword "$line" "$APP_NOT_RESPONDING_PATTERN"`
	
  	if [ $crash_flag -ne 0 -o $respond_flag -ne 0 ]; then
		echo "****************************************************************************************"
		flag=1
        if [ $crash_flag -eq 1 ]; then
            echo "===>screenshots for crash "
            screenshots "${filename}_crash"
        fi

        if [ $respond_flag -eq 1 ]; then
            echo "===>screenshots for crash "
            screenshots "${filename}_non_respond"
        fi
	fi

	if [ $flag -ne 0 ]; then
		echo $line
	fi

	mm=`find_keyword "$line" "$EVENTS_INJECT_PATTERN"`
	if [ $mm -gt 0 ]; then
        #screen shot 
        img_num=$((img_num+1))
        echo "===>screenshots: "$img_num
        screenshots "${filename}_${img_num}"

		num=`echo $line | grep -o "[0-9]*"`
		if [ $event_num -ne $num ]; then
			echo "********************************************************************************************"
			surplus=`expr $event_num - $num`
			echo "Has $surplus event not running..."
			echo $surplus > surplus
		else
			echo $line
			echo $SUCCESS_PATTERN " Success."
			break
		fi

	fi

done

exit 0
result=0
flag=0
cat "$logfile" | while read line
do 
     	#echo '---->'$line
  line=`echo " "$line | sed s/**//g `
  mm=`awk 'BEGIN {print index("'"$line"'","'"$BEGIN_PATTERN"'")}'`
  if [ $mm -gt 0 ]; then
    echo $line
    continue
  fi

  mm=`awk 'BEGIN {print index("'"$line"'","'"$SUCCESS_PATTERN"'")}'`
  if [ $mm -gt 0 ]; then
    echo $line
    exit 0
  fi

  mm=`awk 'BEGIN {print index("'"$line"'","'"$EVENTS_INJECT_PATTERN"'")}'`
  if [ $mm -gt 0 ]; then
    echo $line
    if [ $result -eq 1 ]; then
      exit $result
    fi
  fi

  if [ $flag -eq 0 ]; then
    mm=`awk 'BEGIN {print index("'"$line"'","'"$CRASH_PATTERN"'")}'`
    if [ $mm -gt 0 ]; then
      echo $line
      result=1
      flag=1
    fi
  else
    echo $line
  fi
done

