#!/bin/bash

TRACE_DIR=/sys/kernel/debug/tracing
TRACE=trace
TRACING_ON=tracing_on
MYRETPROBE_ENABLE=events/kprobes/myretprobe/enable
KPROBE_EVENTS=kprobe_events
MYRETPROBE=myretprobe

traceInit () {

	echo 0 > "${TRACE_DIR}/${TRACING_ON}"
	if [ -e "${TRACE_DIR}/${MYRETPROBE_ENABLE}" ];then
		echo 0 > "${TRACE_DIR}/${MYRETPROBE_ENABLE}"
	fi
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

traceReport () {
	local FUNCTIONNAME=$1
	local DATE=`date --iso-8601='s'`
	echo "[${DATE}]DROPPING DETECTED -----> ${FUNCTIONNAME}"
}

traceProcessDebug () {
	tail -n +12 $TRACE_DIR/$TRACE | awk '{print $6,$8,$9}' | sed 's/(//; s/)//' | sort -n | uniq -c

}

traceKfreeskb() {
	local TEMPFILE=kfreeskb.tmp
	cat $1 | grep -o "${MYRETPROBE}.*" | grep '<- kfree_skb' | uniq | awk '{print $2}' | grep -oP '(\().*(\+)' | sed 's/(//;s/+//' > $TEMPFILE

	if [ -e "$TEMPFILE" ];then
		while read FUNCTION
		do
			traceReport $FUNCTION
		done < $TEMPFILE

		rm $TEMPFILE
		sed -i '/<- kfree_skb/d' $1
	fi
}
traceOthers () {
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

traceProcess () {
	#This function examine all suspicious functions 
	#by processing raw trace log.

	#If a function is saw as a dropping function,
	#it will be reported to terminal
	#by calling traceReport

	#At present, we have previously identified the features of the following 3 functions

	#'tracedata.tmp' is a copy of raw trace log
	#'tmp' file will be deleted at the end of this function.


	local TEMPFILE=tracedata.tmp
	tail -n +12 $TRACE_DIR/$TRACE | grep $MYRETPROBE > $TEMPFILE

	if [ -e "$TEMPFILE" ];then
		traceKfreeskb $TEMPFILE
		traceOthers $TEMPFILE
		rm $TEMPFILE
	fi

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

	local SWITCH=1 	#set main function execute forever
	local SLEEPTIME=0.1

	echo -e "\033[31mDETECTING... \033[0m"

	while [ $SWITCH = '1' ];
	do
		detectDropping 
		sleep $SLEEPTIME
	done

}

main
