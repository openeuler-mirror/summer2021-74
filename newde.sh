#!/bin/bash

TRACE_DIR=/sys/kernel/debug/tracing
TRACE=trace
TRACE_PIPE=trace_pipe
TRACING_ON=tracing_on
SET_GRAPH_FUNCTION=set_graph_function
TRACING_THRESH=tracing_thresh
CURRENT_TRACER=current_tracer
THRESH=100	#set the delay thresh of function, default setting is 100us

traceInit () {

	echo 0 > "${TRACE_DIR}/${TRACING_ON}"
	echo > "${TRACE_DIR}/${SET_GRAPH_FUNCTION}"
	echo nop > "${TRACE_DIR}/${CURRENT_TRACER}"
	echo 0 > "${TRACE_DIR}/${TRACING_THRESH}"
	echo > "${TRACE_DIR}/${TRACE}"
	timeout 0.1 cat "${TRACE_DIR}/${TRACE_PIPE}" > /dev/null
	#echo '                  ---traceInit---                '
}

traceOn () {

	echo udp_sendmsg >> "${TRACE_DIR}/${SET_GRAPH_FUNCTION}"
	echo udp_recvmsg >> "${TRACE_DIR}/${SET_GRAPH_FUNCTION}"
	echo function_graph > "${TRACE_DIR}/${CURRENT_TRACER}"
	echo $THRESH > "${TRACE_DIR}/${TRACING_THRESH}"
	echo 1 > "${TRACE_DIR}/${TRACING_ON}"
	#echo '                  ---traceOn---                '
}

function stopProgram () {
	echo -e "\nstop tracing"
	traceInit
}

traceProcess () {
	local AWKSCRIPT=newde.awk
	awk -f $AWKSCRIPT ${TRACE_DIR}/${TRACE_PIPE}
}

main () {
	#trap 'stopProgram' INT
	traceInit
	traceOn
	traceProcess
}

main
