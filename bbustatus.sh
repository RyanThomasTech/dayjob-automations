#!/bin/bash
if [ $# -eq 0 ]; then
	echo -ne "Type RMA number\n"
	read RMA_NUM
elif [ $# -gt 1 ]; then
	echo -n "Too many arguments supplied. Correct usage: bbustatus [RMA_NUM]"
	exit 1
else 
	RMA_NUM=$1
fi

if [ ! -f "/upload/thomasr/$RMA_NUM.csv" ]; then
	touch /upload/thomasr/$RMA_NUM.csv
	echo "did not find $RMA_NUM.csv"
	echo "SERIAL NUMBER,PASS OR FAIL" | tee /upload/thomasr/$RMA_NUM.csv >/dev/null
fi
/opt/MegaRAID/storcli/storcli64 /c0 show > /tmp/bbu_results
/opt/MegaRAID/storcli/storcli64 /c0/cv show status | tee -a /tmp/bbu_results
awk -f /upload/thomasr/bbuinfo-to-csv.awk /tmp/bbu_results >> /upload/thomasr/$RMA_NUM.csv
