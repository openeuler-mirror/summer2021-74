#!/bin/bash

function clean() {
	echo 0 > /sys/kernel/debug/tracing/events/kprobes/myprobe/enable
	echo 0 > /sys/kernel/debug/tracing/events/kprobes/myretprobe/enable
	echo 0 > /sys/kernel/debug/tracing/tracing_on
	echo > /sys/kernel/debug/tracing/kprobe_events
}

function kon() {
	echo 'p:myprobe udp_send_skb.isra.0 $arg1' >> /sys/kernel/debug/tracing/kprobe_events
	echo 'r:myretprobe ip_make_skb $retval' >> /sys/kernel/debug/tracing/kprobe_events
	echo 'p:myprobe dev_queue_xmit $arg1' >> /sys/kernel/debug/tracing/kprobe_events
	echo 'p:myprobe xmit_one.constprop.0 $arg1' >> /sys/kernel/debug/tracing/kprobe_events
	echo 1 > /sys/kernel/debug/tracing/events/kprobes/myprobe/enable
	echo 1 > /sys/kernel/debug/tracing/events/kprobes/myretprobe/enable
	echo 1 > /sys/kernel/debug/tracing/tracing_on
}
clean
kon
