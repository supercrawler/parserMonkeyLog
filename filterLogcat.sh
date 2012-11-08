#!/bin/sh 

if [ $# -ne 1 ]; then
    echo "Usage: $0 devices"
    echo "devices: 38334C1B4C5F00EC"
    echo "$0 38334C1B4C5F00EC"
    exit 1
fi
devices="$1"
logfile="log"

open_logcat_flag="open_logcat_flag"
#define filter tag
REPORT_FILE_PATH_PATTERN="Dolphin_Report_File_Path:"

path="reports"
rm -rf $path
if [ ! -d $path ]; then
    mkdir $path
fi

>mm
#clear logfile content.
flag=1
adb -s $devices logcat | while read line;
do
    mm=`awk 'BEGIN {print index("'"$line"'", "'"$REPORT_FILE_PATH_PATTERN"'")}'`
    if [ -n $mm -a $mm -gt 0 ]; then
        echo $line 
        cur_date=`date '+%Y%m%d%H%M%S'`
        filename="$path/report_${cur_date}.zip"
        #echo $filename
        #echo "==================>"
        remote_file_path=`echo "$line" | awk -F":" '{print $3}'`
       # echo $remote_file_path
        #echo "---------------------->"
        echo $devices  >>mm
        echo $remote_file_path>>mm
        echo $filename >>mm
        #echo "adb -s "$devices" pull "$remote_file_path  $filename
        
        #shell_script="$filename"
        #shell_script=$shell_script$remote_file_path
        #echo $shell_script
        #shell_script=`echo "adb -s $devices pull $remote_file_path 123.zip"`
        #echo $shell_script
        #adb -s "$devices" pull "/$remote_file_path" "$filename"
        cat mm | xargs ./pull.sh
        #./pull.sh "$devices" "$remote_file_path" "$filename"
        #adb -s 38334C1B4C5F00EC pull  /storage/sdcard0/download/report.zip $filename

    fi

    #clear logcat information
    #adb -s $devices logcat -c 
    flag=`cat "$open_logcat_flag"`
    if [ -n $flag -a $flag -gt 0 ]; then
        echo $line >> $logfile
    fi 
done

#rm if open logcat flag file.
rm $open_logcat_flag
rm mm
#echo 1 > $open_logcat_flag
