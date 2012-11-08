#!/bin/sh 

if [[ $# -ne 1 ]]; then
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
if [[ ! -d $path ]]; then
    mkdir $path
fi

removeInvalideChar()
{

    if [[ $# -ne 1 ]]; then
        echo "Usage $0 line"
        exit 1;
    fi

    echo "$1" | tr -d [:cntrl:]
}

#clear logfile content.
flag=1
adb -s "$devices" logcat | while read line;
do
    #line=`echo "$line" | sed  -e 's/\./ /g' `
    line=`removeInvalideChar "$line"`
    #echo $line
    #mm=`awk 'BEGIN {print index("'"$line"'", "'"$REPORT_FILE_PATH_PATTERN"'")}'`
    mm=`echo $line | awk '/ Dolphin_Report_File_Path/{print;}'`
    if [[ -n $mm ]]; then
        echo $line 
        cur_date=`date '+%Y%m%d%H%M%S'`
        filename="$path/report_${cur_date}.zip"
        remote_file_path=`echo "$line" | awk -F":" '{print $3}' | sed -e 's/ /\./g' `
      
        remote_file=`removeInvalideChar "$remote_file_path"`
        cur_file=`removeInvalideChar "$filename"`

        echo "$devices"
        echo $remote_file
        echo $cur_file
        adb -s "$devices" pull $remote_file $cur_file 
        #cat mm | xargs ./pull.sh
    fi

    flag=`cat "$open_logcat_flag"`
    if [[ -n $flag && $flag -gt 0 ]]; then
        echo $line >> $logfile
    else
        break
    fi 
done

#rm $open_logcat_flag
echo "Logcat received signal and  exit success."

echo ""
exit 0