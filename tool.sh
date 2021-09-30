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
SET_GRAPH_FUNCTION=set_graph_function
TRACING_THRESH=tracing_thresh
CURRENT_TRACER=current_tracer
GLOBALTHRESH=10000

function kprobeInit() {

        if [[ -e "${TRACE_DIR}/${MYPROBE_ENABLE}" ]];then
                echo 0 > "${TRACE_DIR}/${MYPROBE_ENABLE}"
        fi

        if [[ -e "${TRACE_DIR}/${MYRETPROBE_ENABLE}" ]];then
                echo 0 > "${TRACE_DIR}/${MYRETPROBE_ENABLE}"
        fi

        echo > "${TRACE_DIR}/${KPROBE_EVENTS}"
        #echo '                  ---traceInit---                '
}

function traceInit() {
	echo 0 > "${TRACE_DIR}/${TRACING_ON}"
	timeout 0.1 cat "${TRACE_DIR}/${TRACE_PIPE}" > /dev/null
	echo > "${TRACE_DIR}/${TRACE}"
}

function functiongraphInit() {
	echo nop > "${TRACE_DIR}/${CURRENT_TRACER}"
	echo > "${TRACE_DIR}/${SET_GRAPH_FUNCTION}"
        echo 0 > "${TRACE_DIR}/${TRACING_THRESH}" 
}

function bothInit() {
	# order of three functions shall not be changed
	traceInit
	kprobeInit
	functiongraphInit
}

function kprobeOn() {
        if [[ -e "${TRACE_DIR}/${MYPROBE_ENABLE}" ]];then
                echo 1 > "${TRACE_DIR}/${MYPROBE_ENABLE}"
        else
                echo "no kprobe event"
                exit -1
        fi
}

function kretprobeOn() {
        if [[ -e "${TRACE_DIR}/${MYRETPROBE_ENABLE}" ]];then
                echo 1 > "${TRACE_DIR}/${MYRETPROBE_ENABLE}"
        else
                echo "no kretprobe event"
                exit -1
        fi

        #echo '                  ---traceOn---                '
}

function functiongraphOn() {

	local THRESH=100
	echo udp_sendmsg > "${TRACE_DIR}/${SET_GRAPH_FUNCTION}"
	echo udp_recvmsg > "${TRACE_DIR}/${SET_GRAPH_FUNCTION}"
	echo function_graph > "${TRACE_DIR}/${CURRENT_TRACER}"
        echo $THRESH > "${TRACE_DIR}/${TRACING_THRESH}" 
}

function traceOn() {
	echo 1 > "${TRACE_DIR}/${TRACING_ON}"
}

function kprobeAddFunction() {
        # add a kprobe function to kprobe_events

        local FUNCTIONNAME=$1
        if [[ $# -ne 1 ]];then
                echo "function kprobeAddFunction requires one parameter"
                return -1
        fi

        echo 'p:myprobe '$1'' >> "${TRACE_DIR}/${KPROBE_EVENTS}"

        return 0
}

function kretprobeAddFunction() {
	# add a kretprobe function to kprobe_events

	local FUNCTIONNAME=$1
	if [[ $# -ne 1 ]];then
		echo "function kretprobeAddFunction requires one parameter"
		return -1
	fi

	echo 'r:myretprobe '$1' $retval' >> "${TRACE_DIR}/${KPROBE_EVENTS}"

	return 0

}

function kprobeDelFunction() {
        # delete one probe entry in kprobe_events

        # echo > "${TRACE_DIR}/${KPROBE_EVENTS}"
        echo '-:myprobe' > "${TRACE_DIR}/${KPROBE_EVENTS}"
}

function kretprobeDelFunction() {
	# delete one probe entry in kprobe_events

	# echo > "${TRACE_DIR}/${KPROBE_EVENTS}"
	echo '-:myretprobe' > "${TRACE_DIR}/${KPROBE_EVENTS}"
}

function dropAddFunction() {
        local DELAYFUNCTIONS=dropfunctions

        if [[ -e "${DELAYFUNCTIONS}" ]];then
		while read LINE
		do
			kretprobeAddFunction $LINE
		done < dropfunctions
	else
		echo "no function for drop detection added"
	fi
}

function delayAddFunction() {
	local FUNCTIONNAME="nop"
	
	FUNCTIONNAME=`cat /proc/kallsyms | grep udp_send_skb | awk '{print $3}'`
	echo "p:myprobe ${FUNCTIONNAME} \$arg1" >> "${TRACE_DIR}/${KPROBE_EVENTS}"
	echo "r:myretprobe ip_make_skb \$retval" >> "${TRACE_DIR}/${KPROBE_EVENTS}"
	echo "p:myprobe dev_queue_xmit \$arg1" >> "${TRACE_DIR}/${KPROBE_EVENTS}"
	FUNCTIONNAME=`cat /proc/kallsyms | grep xmit_one | awk '{print $3}'`
	echo "p:myprobe ${FUNCTIONNAME} \$arg1" >> "${TRACE_DIR}/${KPROBE_EVENTS}"

	#echo 'p:myprobe udp_send_skb.isra.0 $arg1' >> "${TRACE_DIR}/${KPROBE_EVENTS}"
	#echo 'r:myretprobe ip_make_skb $retval' >> "${TRACE_DIR}/${KPROBE_EVENTS}"
	#echo 'p:myprobe dev_queue_xmit $arg1' >> "${TRACE_DIR}/${KPROBE_EVENTS}"
	#echo 'p:myprobe xmit_one.constprop.0 $arg1' >> "${TRACE_DIR}/${KPROBE_EVENTS}"
}

function consumptionAddFunction() {
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

function consumptionInit() {
	#kprobeInit
	#traceInit
	bothInit
}

function consumptionOn() {
	kprobeOn
	kretprobeOn
	traceOn
}

function delayInit() {
	#kprobeInit
	bothInit
}

function delayOn() {
	kprobeOn
	kretprobeOn
	traceOn
}

function dropInit() {
	#kprobeInit
	#traceInit
	bothInit
}

function dropOn() {
	kretprobeOn
	traceOn
}

function readTracepipe() {
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

function getTracedata() {

	local SWITCH=1
	local COUNT=0

	readTracepipe $COUNT
 
}

function getTracedataName() {
	local DATA_DIR="data"
	local TRACEDATA_NAME=tracedata_name.tmp
	
	ls $DATA_DIR > $TRACEDATA_NAME

}

function deeperProcess() {
	echo "deeperProcess"
	awk '{gsub(/\)/, "", $8); gsub(/arg1/,"retval", $9); if( $9 !~/0x0/ ) print $8,$9}' ${TRACE_DIR}/${TRACE_PIPE}
}

function kprobeDeeper() {
	local FUNCTIONNAME=$1

	if [[ ! -n "$1" ]];then
		echo "At least one parameter needed for kprobeDeeper!"
		return -1
	fi
	#echo $FUNCTIONNAME
	case $FUNCTIONNAME in
		"__udp_queue_rcv_skb")
			dropInit
			kretprobeAddFunction __udp_enqueue_schedule_skb
			dropOn
			deeperProcess
			;;
		"udp_read_sock")
			dropInit
			kretprobeAddFunction recv_actor
			dropOn
			deeperProcess
			;;
		"udp_queue_rcv_one_skb")
			# dropping if the queue is full
			dropInit
			kretprobeAddFunction xfrm4_policy_check
			kretprobeAddFunction sk_filter_trim_cap 
			dropOn
			deeperProcess
			;;
	esac
}

function kprobeReport() {
	local COUNT=$1
	local FUNCTIONNAME=$2
	local DATE=`date --iso-8601='s'`
	
	echo -e "[${DATE}]\t${COUNT}\t${FUNCTIONNAME}"
}

function kprobeProcessDebug() {
	tail -n +12 $TRACE_DIR/$TRACE | awk '{print $6,$8,$9}' | sed 's/(//; s/)//' | sort -n | uniq -c

}

function kprobeKfreeskb() {
	local TEMPFILE=kfreeskb.tmp

	cat $1 | grep "${MYRETPROBE}" | grep -oP '(\().*(\+)' | sed 's/(//;s/+//' | uniq -c > $TEMPFILE

	if [ -s "$TEMPFILE" ];then
		while read FUNCTION
		do
			local FUNCTIONNAME=`echo $FUNCTION | awk '{print $2}'`
			kprobeDeeper $FUNCTIONNAME
			if [[ ${FUNCTIONNAME} != "inet_recvmsg" ]];then
				kprobeReport $FUNCTION
			fi
		done < $TEMPFILE

		sed -i '/<- kfree_skb/d' $1
	fi
}

function kprobeOthers() {
	local TEMPFILE=others.tmp

	cat $1 | awk '{print $6,$8,$9}' | sed 's/(//; s/)//' | sort -n | uniq -c > $TEMPFILE
	#tail -n +12 $TRACE_DIR/$TRACE | awk '{print $6,$8,$9}' | sed 's/(//; s/)//' | sort -n | uniq -c > $TEMPFILE
	if [[ -e "${TEMPFILE}" ]];then
		
		# examine skb_release_data 
		FUNCTION=`cat ${TEMPFILE} | grep skb_release_data | grep -o kfree_skb.part`
		if [[ "${FUNCTION}" == "kfree_skb.part" ]];then
			traceReport skb_release_data
		fi
		sed -i '/skb_release_data/d' $TEMPFILE
		sed -i '/skb_release_data/d' $1

		#examine skb_release_head_state
		FUNCTION=`cat ${TEMPFILE} | grep skb_release_head_state | grep -o kfree_skb.part`
		if [[ "${FUNCTION}" == "kfree_skb.part" ]];then
			traceReport skb_release_head_state
		fi
		sed -i '/skb_release_head_state/d' $TEMPFILE
		sed -i '/skb_release_head_state/d' $1

		#detect dequeue_skb
		RETVALUE=`cat ${TEMPFILE} | grep dequeue_skb | grep -o 'arg1=.*' | uniq | awk -F '=' '{print $2}'`
		#if [[ "${RETVALUE}" != "0x0" -a "${RETVALUE}" != "" ]];then
		#	traceReport dequeue_skb
		#fi
		#sed -i '/dequeue_skb/d' $TEMPFILE
		#sed -i '/dequeue_skb/d' $1

		rm $TEMPFILE
	fi
}

function kprobeProcess() {
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

function dropProcess() {
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

function netstatReport() {
	netstat -s -u | tail -n +3
}

function cleanProcess() {
	ps -auf | grep tool.sh | awk '{print "kill -9 "$2}' | sh
}

function cleanTempfile() {
	local DATA_DIR="data"
	rm -f *.tmp
	rm -f ${DATA_DIR}/*.tmp
}

function exitProgram() {
	echo -e "]\nperforming cleaning up"
	cleanTempfile
	bothInit
	echo "cleaned"
	#cleanProcess
	exit 2
}

function displayUsage() {
	echo "Usage: ${0} 	[ -t | --thresh ] time"
	echo "		  	[ -d | --delay ] [ -c | --consumption ]"
	echo "		  	[ -l | --loss ] [ -h | --help ]"
	echo ""
	echo "      -t, --thresh	Set time thresh, default is 10000us"
	echo "      -d, --delay	 	Detect udp functions delay"
	echo "      -c, --consumption	Examine single function time consumption"
	echo "      -l, --loss		Detect packet loss"
	echo "      -h, --help		Print this help message"
}

function detectDrop() {
	local SWITCH=1
	local COUNT=0
	local RES=0
	local REPORT=1


	trap 'exitProgram' 2
	echo -e "\033[31mDROP DETECTING... \033[0m"
	#bothInit && bothOn
	dropInit 
	dropAddFunction
       	dropOn

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

function detectDelay() {
	local AWKSCRIPT=delay.awk
	local THRESH=10000

	if [[ $# -eq 1 ]];then
		THRESH=$1
	fi
	echo $THRESH

	trap 'exitProgram' 2
	echo -e "\033[31mDELAY DETECTING... \033[0m"
	delayInit
	delayAddFunction
	delayOn

        if [[ -e "${AWKSCRIPT}" ]];then
                awk -v DELAYTIME=$THRESH -f $AWKSCRIPT $TRACE_DIR/$TRACE_PIPE
	else
		echo "require awk script to perform delay detection"
	fi
}

function examineConsumption() {
        # execute awk script to print delay functions
        local AWKSCRIPT=consumption.awk
        #local AWKSCRIPT=calculate.awk
	local THRESH=10000

	if [[ $# -eq 1 ]];then
		THRESH=$1
	fi
	trap 'exitProgram' 2
	echo -e "\033[31mCONSUMPTION EXAMINING... \033[0m"
	consumptionInit
	consumptionAddFunction
	consumptionOn
        if [[ -e "${AWKSCRIPT}" ]];then
                awk -v DELAYTIME=$THRESH -f $AWKSCRIPT $TRACE_DIR/$TRACE_PIPE
	else
		echo "require awk script to perform delay detection"
	fi
}

PARSED_ARGUMENTS=$(getopt -n tool -o t:hldc --long thresh:,help,loss,delay,consumption -- "$@")
VALID_ARGUMENTS=$?

if [[ "${VALID_ARGUMENTS}" != "0" ]];then
	displayUsage
	exit 0
fi

eval set -- "${PARSED_ARGUMENTS}"

while :
do
	case "$1" in
		-t | --thresh)
			GLOBALTHRESH=$2
			shift 2
			;;
		-h | --help)
			displayUsage
			exit 0
			;;
		-l | --loss)
			detectDrop
			exit 0
			;;
		-d | --delay)
			if [[ $2 == "-t" || $2 == "--thresh" ]];then
				GLOBALTHRESH=$3
			fi
			detectDelay $GLOBALTHRESH
			exit 0
			;;
		-c | --consumption)
			if [[ $2 == "-t" || $2 == "--thresh" ]];then
				GLOBALTHRESH=$3
			fi
			examineConsumption $GLOBALTHRESH
			exit 0
			;;
		*)
			displayUsage
			exit 0
			;;
	esac
done

