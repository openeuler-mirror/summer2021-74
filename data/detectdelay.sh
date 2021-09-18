#!/bin/bash

TRACE_DIR=/sys/kernel/debug/tracing
TRACE=trace
TRACE_PIPE=trace_pipe
TRACING_ON=tracing_on
MYRETPROBE_ENABLE=events/kprobes/myretprobe/enable
MYPROBE_ENABLE=events/kprobes/myprobe/enable
KPROBE_EVENTS=kprobe_events
MYRETPROBE=myretprobe
MYPROBE=myprobe

kprobeInit() {
	
	if [[ -e "${TRACE_DIR}/${MYPROBE_ENABLE}" ]];then
		echo 0 > "${TRACE_DIR}/${MYPROBE_ENABLE}"
	fi

	if [[ -e "${TRACE_DIR}/${MYRETPROBE_ENABLE}" ]];then
		echo 0 > "${TRACE_DIR}/${MYRETPROBE_ENABLE}"
	fi

	echo > "${TRACE_DIR}/${KPROBE_EVENTS}"
	#echo '                  ---traceInit---                '
}

traceInit() {
	echo 0 > "${TRACE_DIR}/${TRACING_ON}"
	timeout 0.1 cat "${TRACE_DIR}/${TRACE_PIPE}" > /dev/null
	echo > "${TRACE_DIR}/${TRACE}"
}

kprobeOn() {
	if [[ -e "${TRACE_DIR}/${MYPROBE_ENABLE}" ]];then
		echo 1 > "${TRACE_DIR}/${MYPROBE_ENABLE}"
	else
		echo "no kprobe event "
	echo 1 > "${TRACE_DIR}/${MYRETPROBE_ENABLE}"
	#echo '                  ---traceOn---                '
}

traceOn() {
	echo 1 > "${TRACE_DIR}/${TRACING_ON}"
}

kprobeAddFunction() {
	# add one function to kprobe_events

	local FUNCTIONNAME=$1
	if [[ $# -ne 1 ]];then
		echo "function kprobeAddFunction requires one parameter"
		return -1
	fi

	echo 'p:myprobe '$1'' >> "${TRACE_DIR}/${KPROBE_EVENTS}"

	return 0
}

kretprobeAddFunction() {
	# add one function to kprobe_events

	local FUNCTIONNAME=$1

	if [[ $# -ne 1 ]];then
		echo "function kretprobeAddFunction requires one parameter"
		return -1
	fi

	echo 'r:myretprobe '$1' $retval' >> "${TRACE_DIR}/${KPROBE_EVENTS}"

	return 0
}

kprobeDelFunction() {
	# delete one probe entry in kprobe_events

	# echo > "${TRACE_DIR}/${KPROBE_EVENTS}"
	echo '-:myprobe' > "${TRACE_DIR}/${KPROBE_EVENTS}"
}

kretprobeDelFunction() {
	# delete one retprobe entry in kprobe_events

	# echo > "${TRACE_DIR}/${KPROBE_EVENTS}"
	echo '-:myretprobe' > "${TRACE_DIR}/${KPROBE_EVENTS}"
}

delayAddFunction() {
	local DELAYFUNCTIONS=delayfunctions
	
	if [[ -e "${DELAYFUNCTIONS}" ]];then
		while read LINE
		do
			kprobeAddFunction $LINE
			kretprobeAddFunction $LINE
		done < delayfunctions
	else
		echo "no function for delay detection added"
	fi
}

readTracepipe() {
	# 
	local COUNT=$1
	local INTERVAL=0.1
	local DATA_DIR="data"
	local FILENAME="tracedata_${COUNT}.tmp"

	if [ $# -ne 1 ];then
		echo "function getTracepipe requires one parameter"
		return -1
	fi

	timeout $INTERVAL cat ${TRACE_DIR}/${TRACE_PIPE} > ${DATA_DIR}/${FILENAME}
}

getTracedata() {

	local SWITCH=1
	local COUNT=0

	readTracepipe $COUNT
 
}

getTracedataName() {
	local DATA_DIR="data"
	local TRACEDATA_NAME=tracedata_name.tmp
	
	ls $DATA_DIR > $TRACEDATA_NAME

}
:<<!
getFunctionName () {
	if [ ! -n "$1" ];then
		echo "At least one parameter needed for getFunctionName!"
		return -1
	fi

	echo $1 | awk '{print $6}' | grep -oP '(\().*(\+)' | sed 's/(//;s/+//' 
}
!
detectDelay() {
	# execute awk script to print delay functions
	local AWKSCRIPT=calculate.awk
	
	if [[ ! -e "${AWKSCRIPT}" ]];then
		
	fi
	awk -f $AWKCRIPT $TRACE_DIR/$TRACE_PIPE
}

kprobeReport() {
	local COUNT=$1
	local FUNCTIONNAME=$2
	local DATE=`date --iso-8601='s'`
	#echo "[${DATE}]DROPPING DETECTED -----> ${FUNCTIONNAME}"
	echo -e "[${DATE}]\t${COUNT}\t${FUNCTIONNAME}"
}

kprobeProcess() {

}

cleanProcess() {
	ps -auf | grep tool.sh | awk '{print "kill -9 "$2}' | sh
}

cleanTempfile() {
	local DATA_DIR="data"
	rm -f *.tmp
	rm -f ${DATA_DIR}/*.tmp
}

exitProgram() {
	echo -e "]\nperforming cleaning up"
	cleanTempfile
	bothInit
	echo "cleaned"
	cleanProcess
	exit 2
}


main() {
	local SWITCH=1

	trap 'exitProgram' 2
TRACE=trace
TRACE_PIPE=trace_pipe
TRACING_ON=tracing_on
MYRETPROBE_ENABLE=events/kprobes/myretprobe/enable
KPROBE_EVENTS=kprobe_events
MYRETPROBE=myretprobe
SET_GRAPH_FUNCTION=set_graph_function
