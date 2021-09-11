#!/bin/awk -f

BEGIN {
	FS="|"
	FUNCTIONS[0]="udp_recvmsg"
	FUNCTIONS[1]="skb_consume_udp"
	FUNCTIONS[2]="__consume_stateless_skb"
	FUNCTIONS[3]="kfree_skbmem"
	FUNCTIONS[4]="kmem_cache_free"
	FUNCTIONS[5]="irq_exit_rcu"
	FUNCTIONS[6]="do_softirq_own_stack"
	FUNCTIONS[7]="__do_softirq"
	FUNCTIONS[8]="net_rx_action"
	FUNCTIONS[9]="napi_poll"
	FUNCTIONS[10]="net_rx_action"
	# placeholder
}

{
	#print $0 | "grep -o '|.*}' | tr -cd ' ' | wc -c" | getline BLANKS
	#if(BLANKS)
	n = gsub(/ /, "", $2)
	gsub("[{}/*^$]", "", $2)
	gsub("*.!", "", $1)
	res = (n-5)/2

	if (res == 0)
		COUNT = COUNT+1
		print $2
	#print $3,$4,"\t",$8 |
}

END {
	# placeholder
}
