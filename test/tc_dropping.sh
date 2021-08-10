#!/bin/bash

TC=tc
IF=ens33
PROBABILITY=50%
PERCENTAGE=25%


DST_CIDR=192.168.10.231/32

FILTER="${TC} filter add dev ${IF} protocol ip parent 1:0 prio 1 u32"

dropLevel1 () {
	echo "DROPPING INIT"

	$TC qdisc add dev $IF root netem loss $PROBABILITY

	echo "DROPPING DONE"
}

dropLevel2 () {
	echo "DROPPING INIT"

	$TC qdisc add dev $IF root netem loss $PROBABILITY $PERCENTAGE

	echo "DROPPING DONE"
}
dropLevel3 () {
	echo "DROPPING INIT"

	$TC qdisc add dev $IF root netem loss gemodel 1% 10% 70% 0.1%

	echo "DROPPING DONE"
}

clean () {
	$TC qdisc del dev $IF root
}

clean
dropLevel1
