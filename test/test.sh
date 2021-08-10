#!/bin/bash

TRACE_DIR=/sys/kernel/debug/tracing
TRACE=trace
TRACING_ON=tracing_on
MYRETPROBE_ENABLE=events/kprobes/myretprobe/enable
KPROBE_EVENTS=kprobe_events

traceInit () {

	echo 0 > "${TRACE_DIR}/${TRACING_ON}"
	echo 0 > "${TRACE_DIR}/${MYRETPROBE_ENABLE}"
	echo > "${TRACE_DIR}/${TRACE}" 
	echo '                  ---traceInit---                '
}

traceOn () {

	echo 1 > "${TRACE_DIR}/${TRACING_ON}"
	echo 1 > "${TRACE_DIR}/${MYRETPROBE_ENABLE}"
	echo '                  ---traceOn---                '
}

kretprobeAddFunction () {
	if [ ! -n "$1" ];then
		echo "At least one parameter needed for KretprobeAddFunction!"
		return -1
	fi
	
	echo 'r:myretprobe '$1' $retval' > "${TRACE_DIR}/${KPROBE_EVENTS}"
	
	return 0

}
kretprobeDelFunction () {
	echo '-:myretprobe' > "${TRACE_DIR}/${KPROBE_EVENTS}"
}

getFunctionName () {
	if [ ! -n "$1" ];then
		echo "At least one parameter needed for getFunctionName!"
		return -1
	fi

	echo $1 | awk '{print $6}' | grep -oP '(\().*(\+)' | sed 's/(//;s/+//' 
}

traceProcess () {
	#This function gets name of functions which return none-zero 
	#by processing raw trace log.
	#'trace_data.tmp' is a copy of raw trace log
	#'tmp' file will be deleted at the end of this function.


	tail -n +12 $TRACE_DIR/$TRACE >> trace_data.tmp
	tail -n +12 $TRACE_DIR/$TRACE >> trace_mydata_debug.tmp
	echo > $TRACE_DIR/$TRACE &

	while read LINE
	do

		$RET=`echo $LINE | grep -o 'arg1=.*' | awk -F '=' '{print $2}'`
		if [ $RET != '0x0' ];then
			echo 'functions return non-zero'
			#echo $LINE | awk '{print $8}' | sed 's/)//' >> functions_suspicious.dat
			echo $LINE | awk '{print $8}' | sed 's/)//'
			echo ' '
			#getFunctionName $LINE >> functions_suspicious.dat
			#echo $LINE | awk '{print $6}' | grep -oP '(\().*(\+)' | sed 's/(//;s/+//' >> functions_suspicious.dat
		fi	
	done < trace_data.tmp
	#cat trace_data.tmp | grep -o 'arg1=.*' | awk -F '=' '{print $2}'
	#rm trace_data.tmp
}

traceKfreeskb () {
	#'trace_kfreeskb.tmp' contains name of functions which call kfree_skb()
	
	tail -n +12 $TRACE_DIR/$TRACE >> trace_kfreeskb.tmp
	while read LINE
	do

		getFunctionName $LINE >> functions_kfreeskb.dat
	done < trace_kfreeskb.tmp
	
}

traceProcessDebug () {
	#This function gets name of functions which return non-zero 
	#by processing raw trace log.
	#'trace_data.tmp' is a copy of raw trace log
	#'tmp' file will be deleted at the end of this function.


	tail -n +12 $TRACE_DIR/$TRACE | awk '{print $6,$8,$9}' | sed 's/(//; s/)//' | sort -n | uniq -c
}

detect_dropping () {
	SWITCH=1 	#set main function execute forever
	FunctionName=$1
	SLEEPTIME=$2
	OUTPUTDIR=$3

	traceInit
	kretprobeDelFunction
	kretprobeAddFunction $FunctionName
	#trace normal situation
	traceOn
	traceProcessDebug > "${OUTPUTDIR}/${FunctionName}/${FunctionName}_normal.dat"
	sleep $SLEEPTIME

	#trace dropping situation
	/bin/bash /root/tc_dropping.sh
	traceInit
	traceOn
	traceProcessDebug > "${OUTPUTDIR}/${FunctionName}/${FunctionName}_dropping.dat"
	sleep $SLEEPTIME
	
	traceInit
	tc qdisc del dev ens33 root

}

main () {
	FILENAME=important-functions
	DIRNAME=important

	while read LINE
	do
		#rm -rf "data/${LINE}"
		mkdir "important/${LINE}"
		detect_dropping $LINE 10 $DIRNAME
		sed -i "/${LINE}/d" $FILENAME
	done < $FILENAME
}

main
