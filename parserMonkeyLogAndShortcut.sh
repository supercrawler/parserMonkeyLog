#!/bin/sh

usage() 
{
  echo "  "
  echo "  "  
  echo "Usage: $0 packagename event_num img_count devices"
  echo " packagename: eg. mobi.mgeek.TunnyBrowser"
  echo " event_num: eg. 10000"
  echo " img_count: eg. 10"
  echo " devices 38334C1B4C5F00EC"
  echo " eg:"
  echo " $0 mobi.mgeek.TunnyBrowser 10000 10 38334C1B4C5F00EC"
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
if [ $((event_num/100/img_count)) -eq 0 ]; then
   echo "event_num must larger than 100*$img_count"
   usage
   exit 1
fi

echo $packagename $event_num $img_count $devices

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
	if [ -n $mm -a $mm -gt 0 ]; then
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
rm -rf $path
if [ ! -d $path ]; then
    mkdir $path
fi

filename=`echo $path/`

crash_file="crash_file_temp"
responding_file="responding_file_temp"
surplus_file="surplus_file_temp"

crash_value=0
responding_value=0


parseLog()
{
    if [ $# -ne 1 ]; then
        echo "Usage $0 event_num"
        exit 1
    fi

    pre_num=0
    cur_num=0
    img_num=1
    event_num=$1

    #if crash_value is null,set it 0
    crash_value=`cat $crash_file`
    echo "crash_value:"$crash_value
    if [ ! $crash_value ]; then
        crash_value=0
    fi

    responding_value=`cat $responding_file`
    if [ ! $responding_value ]; then
        responding_value=0
    fi
    echo "responding_value:"$responding_value

    echo "event_num:"$event_num
    div=$((event_num/100/img_count))
    if [ $div -lt 5 ]; then
        div=5
    fi

    echo "div:"$div
    adb -s $devices shell monkey -p $packagename -v $event_num | while read line
    do 
        line=`echo " "$line | sed s/**//g `
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
                echo "$event_num : $line"
                pre_num=$cur_num

                #shortcut img
                if [ $((img_num%div)) -eq 0 ]; then
                    echo "===>screenshots: "$img_num
                    cur_date=`date '+%Y%m%d_%H%M%S'`
                    echo $cur_date
                    screenshots "${filename}${cur_date}_${img_num}"
                fi
                img_num=$((img_num+1))
            fi
            continue
        fi

        #filter crash log and not responding log
        crash_flag=`find_keyword "$line" "$CRASH_PATTERN"`
        respond_flag=`find_keyword "$line" "$APP_NOT_RESPONDING_PATTERN"`
    
        if [ $crash_flag -ne 0 -o $respond_flag -ne 0 ]; then
            echo "********************************************************************************************"
            flag=1
            cur_date=`date '+%Y%m%d_%H%M%S'`
            if [ $crash_flag -eq 1 ]; then
                echo "===>screenshots for crash "
                screenshots "${filename}crash_${cur_date}_${crash_value}"
                crash_value=$((crash_value+1))
                echo $crash_value > $crash_file 
            fi

            if [ $respond_flag -eq 1 ]; then
                echo "===>screenshots for not responding "
                screenshots "${filename}non_respond_${cur_date}_${responding_value}"
                responding_value=$((responding_value+1))
                echo $responding_value > $responding_file
            fi
        fi

        if [ $flag -ne 0 ]; then
            echo $line
        fi

        mm=`find_keyword "$line" "$EVENTS_INJECT_PATTERN"`
        if [ $mm -gt 0 ]; then
            #screen shot 
            #img_num=$((img_num+1))
            #echo "===>screenshots: "$img_num
            #cur_date=`date '+%Y%m%d_%H%M%S'`
            #screenshots "${filename}${cur_date}_${img_num}"

            num=`echo $line | grep -o "[0-9]*"`
            if [ $event_num -ne $num ]; then
                echo "********************************************************************************************"
                surplus=$((event_num-num))
                echo "Has $surplus event not running..."
                echo $surplus > $surplus_file

                #set return value
                return 1
            else
                echo $line
                echo $SUCCESS_PATTERN " Success." 
                return 0
            fi

        fi

    done

}

#clear crash file and not responding file value.
echo 0 > $crash_file
echo 0 > $responding_file
>$surplus_file

logfile="log"
>$logfile
open_logcat_flag="open_logcat_flag"

#set flag 1 to open filter adb logcat log information.
echo 1 > $open_logcat_flag
#start filter log info
./filterLogcat.sh "$devices" &
while [ 1 ];
do
    #parser monkey log information.
    parseLog $event_num
    res=`echo $?`
    if [ $res -ne 0 ]; then
        event_num=`cat $surplus_file`
        if [ ! -n " $event_num" ]; then
            break;
        fi
        echo "==========================================>"
    else
        break;
    fi
done

#set flag to stop filter adb logcat log information.
echo 0 > $open_logcat_flag
rm $crash_file
rm $responding_file
rm $surplus_file