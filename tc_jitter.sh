#!/bin/bash

TC=tc
IF=ens33
LIMIT=1mbit

DST_CIDR=192.168.10.231/32

FILTER="$TC filter add dev $IF protocol ip parent 1:0 prio 1 u32"

shape () {
	echo "SHAPING INIT"

	$TC qdisc add dev $IF root handle 1:0 htb default 30

	$TC class add dev $IF parent 1:0 classid 1:1 htb rate $LIMIT

	$FILTER match ip dst $DST_CIDR flowid 1:1

	echo "SHAPING DONE"
}

clean () {
	$TC qdisc del dev $IF root
}

clean
shape
