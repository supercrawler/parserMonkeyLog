#!/bin/sh

adb logcat -c
if [ $# -ne 1 ]; then
  echo "Usage: $0 logfile "
  exit 1
fi

logfile=$1
#define filter keyword
BEGIN_PATTERN=":Monkey:"
SUCCESS_PATTERN="Monkey finished"
EVENTS_INJECT_PATTERN="Events injected:"
CRASH_PATTERN="CRASH:"
APP_NOT_RESPONDING_PATTERN="APPNOTRESPONDING:"

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

