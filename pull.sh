#!/bin/sh 

echo "<=============================>"
echo $1
echo $2
echo $3
echo "<================================>"

device=`echo $1 | tr -d [:cntrl:]`
remote_file=`echo $2 | tr -d [:cntrl:]`
cur_file=`echo $3 | tr -d [:cntrl:]`

echo $device
echo $remote_file
echo $cur_file

adb -s $device pull $remote_file $cur_file 
