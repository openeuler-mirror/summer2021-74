#!/bin/bash

TRACE_DIR=/sys/kernel/debug/tracing
TRACE=trace
TRACE_PIPE=trace_pipe
TRACING_ON=tracing_on
MYRETPROBE_ENABLE=events/kprobes/myretprobe/enable
KPROBE_EVENTS=kprobe_events
MYRETPROBE=myretprobe
SET_GRAPH_FUNCTION=set_graph_function
TRACING_THRESH=tracing_thresh
CURRENT_TRACER=current_tracer

kprobeInit () {

	if [[ -e "${TRACE_DIR}/${MYRETPROBE_ENABLE}" ]];then
		echo 0 > "${TRACE_DIR}/${MYRETPROBE_ENABLE}"
	fi
	echo > ${TRACE_DIR}/${KPROBE_EVENTS} 
	#echo '                  ---traceInit---                '
}


traceInit () {
	echo 0 > "${TRACE_DIR}/${TRACING_ON}"
	timeout 0.1 cat "${TRACE_DIR}/${TRACE_PIPE}" > /dev/null
	echo > "${TRACE_DIR}/${TRACE}"
}

functiongraphInit () {
	echo nop > "${TRACE_DIR}/${CURRENT_TRACER}"
	echo > "${TRACE_DIR}/${SET_GRAPH_FUNCTION}"
        echo 0 > "${TRACE_DIR}/${TRACING_THRESH}" 
}

bothInit () {
	# order of three functions shall not be changed
	traceInit
	kprobeInit
	functiongraphInit
}

kprobeOn () {

	echo 1 > "${TRACE_DIR}/${MYRETPROBE_ENABLE}"
	#echo '                  ---traceOn---                '
}

functiongraphOn () {

	local THRESH=100
	echo udp_sendmsg > "${TRACE_DIR}/${SET_GRAPH_FUNCTION}"
	echo udp_recvmsg > "${TRACE_DIR}/${SET_GRAPH_FUNCTION}"
	echo function_graph > "${TRACE_DIR}/${CURRENT_TRACER}"
        echo $THRESH > "${TRACE_DIR}/${TRACING_THRESH}" 
}

traceOn () {
	echo 1 > "${TRACE_DIR}/${TRACING_ON}"
}

bothOn () {
	# order of functions shall not be changed
	dropAddFunction && kprobeOn
	functiongraphOn
	traceOn
}

kretprobeAddFunction () {
	# add one function to kprobe_events

	local FUNCTIONNAME=$1
	if [[ $# -ne 1 ]];then
		echo "function kretprobeAddFunction requires one parameter"
		return -1
	fi

	echo 'r:myretprobe '$1' $retval' >> "${TRACE_DIR}/${KPROBE_EVENTS}"

	return 0

}

kretprobeDelFunction () {
	# delete one probe entry in kprobe_events

	# echo > "${TRACE_DIR}/${KPROBE_EVENTS}"
	echo '-:myretprobe' > "${TRACE_DIR}/${KPROBE_EVENTS}"
}

dropAddFunction () {
	while read LINE
	do
		kretprobeAddFunction $LINE
	done < functions
}

readTracepipe () {
	# 
	local COUNT=$1
	local INTERVAL=0.1
	local DATA_DIR="data"
	local FILENAME="tracedata_${COUNT}.tmp"
	if [[ $# -ne 1 ]];then
		echo "function getTracepipe requires one parameter"
		return -1
	fi
	timeout $INTERVAL cat ${TRACE_DIR}/${TRACE_PIPE} > ${DATA_DIR}/${FILENAME}
}

getTracedata () {

	local SWITCH=1
	local COUNT=0

	readTracepipe $COUNT
 
}
:<<!
getTracedata () {

	local SWITCH=1
	local COUNT=0

	while [ $SWITCH = "1" ];
	do
		readTracepipe $COUNT
		let COUNT=(COUNT+1)%1000
	done
}
!
getTracedataName () {
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

kprobeReport () {
	local COUNT=$1
	local FUNCTIONNAME=$2
	local DATE=`date --iso-8601='s'`
	#echo "[${DATE}]DROPPING DETECTED -----> ${FUNCTIONNAME}"
	echo -e "[${DATE}]\t${COUNT}\t${FUNCTIONNAME}"
}

kprobeProcessDebug () {
	tail -n +12 $TRACE_DIR/$TRACE | awk '{print $6,$8,$9}' | sed 's/(//; s/)//' | sort -n | uniq -c

}

kprobeKfreeskb() {
	local TEMPFILE=kfreeskb.tmp
	cat $1 | grep "${MYRETPROBE}" | grep -oP '(\().*(\+)' | sed 's/(//;s/+//' | uniq -c > $TEMPFILE
	#cat $1 | grep "${MYRETPROBE}.*" | grep '<- kfree_skb' | uniq | awk '{print $5}' | grep -oP '(\().*(\+)' | sed 's/(//;s/+//' > $TEMPFILE
	#cat $1 | grep -o "${MYRETPROBE}.*" | grep '<- kfree_skb' | uniq | grep -oP '(\().*(\+)' | sed 's/(//;s/+//' > $TEMPFILE

	if [ -s "$TEMPFILE" ];then
		while read FUNCTION
		do
			kprobeReport $FUNCTION
		done < $TEMPFILE

		#rm $TEMPFILE
		sed -i '/<- kfree_skb/d' $1
	fi
}

kprobeOthers () {
	local TEMPFILE=others.tmp

	cat $1 | awk '{print $6,$8,$9}' | sed 's/(//; s/)//' | sort -n | uniq -c > $TEMPFILE
	#tail -n +12 $TRACE_DIR/$TRACE | awk '{print $6,$8,$9}' | sed 's/(//; s/)//' | sort -n | uniq -c > $TEMPFILE
	if [ -e "${TEMPFILE}" ];then
		#examine skb_release_data 
		FUNCTION=`cat ${TEMPFILE} | grep skb_release_data | grep -o kfree_skb.part`
		if [ "$FUNCTION" == "kfree_skb.part" ];then
			traceReport skb_release_data
		fi
		sed -i '/skb_release_data/d' $TEMPFILE
		sed -i '/skb_release_data/d' $1

		#examine skb_release_head_state
		FUNCTION=`cat ${TEMPFILE} | grep skb_release_head_state | grep -o kfree_skb.part`
		if [ "$FUNCTION" == "kfree_skb.part" ];then
			traceReport skb_release_head_state
		fi
		sed -i '/skb_release_head_state/d' $TEMPFILE
		sed -i '/skb_release_head_state/d' $1

		#detect dequeue_skb
		RETVALUE=`cat ${TEMPFILE} | grep dequeue_skb | grep -o 'arg1=.*' | uniq | awk -F '=' '{print $2}'`
		if [ "$RETVALUE" != "0x0" -a "$RETVALUE" != "" ];then
			traceReport dequeue_skb
		fi
		sed -i '/dequeue_skb/d' $TEMPFILE
		sed -i '/dequeue_skb/d' $1

		rm $TEMPFILE
	fi
}

kprobeProcess () {
	#This function examine all suspicious functions 
	#by processing raw trace log.

	#If a function is saw as a dropping function,
	#it will be reported to terminal
	#by calling traceReport

	#At present, we have previously identified the features of the following 3 functions

	#'tracedata.tmp' is a copy of raw trace log
	#'tmp' file will be deleted at the end of this function.


	#local TEMPFILE=tracedata.tmp
	#tail -n +12 $TRACE_DIR/$TRACE | grep $MYRETPROBE > $TEMPFILE

	local TRACEDATA=$1
	if [[ -e "${TRACEDATA}" ]];then
		kprobeKfreeskb $TRACEDATA
		#traceOthers $TEMPFILE
		#rm $TEMPFILE
	fi

}

dropProcess () {
	local DATA_DIR=data
	local TRACEDATA_NAME=tracedata_name.tmp
	local NOTEMPTY=0
	readTracepipe 0
	getTracedataName

	NOTEMPTY=`wc -l ${TRACEDATA_NAME} | awk '{print $1}'`

	#if [ -s $TRACEDATA_NAME ];then
	if [[ "${NOTEMPTY}" -ne '0' ]];then
		while read LINE
		do
			kprobeProcess $DATA_DIR/$LINE
		done < $TRACEDATA_NAME
		return 0
	fi
	return 1
}

dropDetect () {
	local SWITCH=1
	local COUNT=0
	local RES=0
	local REPORT=1

	while [[ "${SWITCH}" = "1" ]];
	do
		let RES=COUNT%15
		
		if [[ "${REPORT}" = "1" ]];then
			clear
			netstatReport
			echo -e "\n"
		fi

		getTracedata
		dropProcess

		if [[ $? = "0" ]];then
			let COUNT=COUNT+1
			let RES=COUNT%15
			if [[ "${RES}" = 0 ]];then
				REPORT=1
			else
				REPORT=0
			fi
		fi
	done
}

:<<!
dropDetect () {
	local SWITCH=1
	local DATA_DIR=data
	local TRACEDATA_NAME=tracedata_name.tmp
	
	while [ $SWITCH = "1" ];
	do
		getTracedataName
		if [ -s $TRACEDATA_NAME ];then
			while read LINE
			do
				kprobeProcess $DATA_DIR/$LINE
			done < $TRACEDATA_NAME
		fi
	done
}
!
detectDropping () {

	kprobeInit && kretprobeDelFunction

	while read FUNCTION
	do
		kretprobeAddFunction $FUNCTION
	done < functions 
	#done < f7 

	kprobeOn && kprobeProcess
	#traceOn && traceProcessDebug



}

netstatReport () {
	netstat -s -u | tail -n +3
}

cleanProcess () {
	ps -auf | grep tool.sh | awk '{print "kill -9 "$2}' | sh
}

cleanTempfile () {
	local DATA_DIR="data"
	rm -f *.tmp
	rm -f ${DATA_DIR}/*.tmp
}

exitProgram () {
	echo -e "]\nperforming cleaning up"
	cleanTempfile
	bothInit
	echo "cleaned"
	cleanProcess
	exit 2
}

main () {
	local SWITCH=1

	trap 'exitProgram' 2
	echo -e "\033[31mDETECTING... \033[0m"
	bothInit && bothOn
	dropDetect

}

main
