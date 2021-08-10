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
	#echo '                  ---traceInit---                '
}

traceOn () {

	echo 1 > "${TRACE_DIR}/${TRACING_ON}"
	echo 1 > "${TRACE_DIR}/${MYRETPROBE_ENABLE}"
	#echo '                  ---traceOn---                '
}

kretprobeAddFunction () {
	#add one function to kprobe_events
	if [ ! -n "$1" ];then
		echo "At least one parameter needed for KretprobeAddFunction!"
		return -1
	fi
	
	echo 'r:myretprobe '$1' $retval' >> "${TRACE_DIR}/${KPROBE_EVENTS}"
	
	return 0

}
kretprobeDelFunction () {
	#clear kprobe_events
	
	
	echo > "${TRACE_DIR}/${KPROBE_EVENTS}"
	#echo '-:myretprobe' > "${TRACE_DIR}/${KPROBE_EVENTS}"
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
:<<!
traceProcess () {
	#This function gets name of functions which return non-zero 
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
!

:<<!
traceReport () {
	DATE=`date --iso-8601='s'`
	case $1 in
		kfree_skb.part.skb_release_data)
			echo "[${DATE}]DROPPING DETECTED -----> skb_release_data"
			;;
		kfree_skb.part.skb_release_head_state)
			echo "[${DATE}]DROPPING DETECTED -----> skb_release_head_state"
			;;
		dequeue_skb)
			echo "[${DATE}]DROPPING DETECTED -----> skb_release_head_state"
			;;
	esac
}
!
traceReport () {
	FUNCTIONNAME=$1
	DATE=`date --iso-8601='s'`
	echo "[${DATE}]DROPPING DETECTED -----> ${FUNCTIONNAME}"
}

traceProcessDebug () {
	tail -n +12 $TRACE_DIR/$TRACE | awk '{print $6,$8,$9}' | sed 's/(//; s/)//' | sort -n | uniq -c

}
traceProcess () {
	#This function examine all suspicious functions 
	#by processing raw trace log.

	#If a function is saw as a dropping function,
	#it will be reported to terminal
	#by calling traceReport

	#At present, we have previously identified the features of the following 3 functions

	#'tracedata.tmp' is a copy of raw trace log
	#'tmp' file will be deleted at the end of this function.


	TEMPFILE=tracedata.tmp

	tail -n +12 $TRACE_DIR/$TRACE | awk '{print $6,$8,$9}' | sed 's/(//; s/)//' | sort -n | uniq -c > $TEMPFILE
	
	#examine skb_release_data 
	FUNCTION=`cat ${TEMPFILE} | grep skb_release_data | grep -o kfree_skb.part`
	if [ "$FUNCTION" == "kfree_skb.part" ];then
		traceReport skb_release_data
	fi
	sed -i '/skb_release_data/d' $TEMPFILE

	#examine skb_release_head_state
	FUNCTION=`cat ${TEMPFILE} | grep skb_release_head_state | grep -o kfree_skb.part`
	if [ "$FUNCTION" == "kfree_skb.part" ];then
		traceReport skb_release_head_state
	fi
	sed -i '/skb_release_head_state/d' $TEMPFILE

	#detect dequeue_skb
	RETVALUE=`cat ${TEMPFILE} | grep dequeue_skb | grep -o 'arg1=.*' | awk -F '=' '{print $2}'`
	if [ "$RETVALUE" != "0x0" ];then
		traceReport dequeue_skb
	fi
	sed -i '/dequeue_skb/d' $TEMPFILE

	rm tracedata.tmp
}

detectDropping () {

	traceInit && kretprobeDelFunction

	while read FUNCTION
	do
		kretprobeAddFunction $FUNCTION
	done < functions 
	#done < f7 
	
	traceOn && traceProcess
	#traceOn && traceProcessDebug

	

}

main () {

	SWITCH=1 	#set main function execute forever
	SLEEPTIME=0.5
	
	echo -e "\033[31mDETECTING... \033[0m"

	while [ $SWITCH = '1' ];
	do
		detectDropping 
		sleep $SLEEPTIME
	done

}

main
