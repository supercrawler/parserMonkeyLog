#/bin/sh

line="// CRASH: com.example.testmonkey (pid 3874)"
CRASH_PATTERN="// CRASH:"

find_keyword()
{
	if [ $# -ne 2 ]; then
		echo "Usage $0 line pattern "
		exit 1
	fi
	mm=`awk 'BEGIN {print index("'"$1"'", "'"$2"'")}'`
	if [ $mm -gt 0 ]; then
		echo 1
		return 0;		
	fi
	echo 0
	return 1
}

find_keyword "$line" "wangi"
echo "function reurn value:"$?
value=`find_keyword "$line" "$CRASH_PATTERN"`
echo $value

if [ $value -gt 0 ]; then
	echo "Find it"
else
	echo "Not find it"
fi
mystr="Events injected: 265"

i=0
while [ $i -lt 10 ]
do

  echo $i
  i=$((i+1))
done

select var in "begin" "end" "exit";
do 
  case $var in 
    "begin")
       echo "starting..."
       break;
       ;;
     "end")
       echo "stoping...."
       break;
       ;;
     "exit")
       echo "exit"
       break;
       ;;
     *)
       echo "ignore..."
       break;
       ;;
     esac
done 

echo "Your have selected $var"
