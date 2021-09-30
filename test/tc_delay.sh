#!/bin/bash

TC=tc
IF=ens33
DELAYTIME=10ms
DISTRIBUTION=10ms
PERCENTAGE=30%
DST_CIDR=192.168.10.231/32

FILTER="${TC} filter add dev ${IF} protocol ip parent 1:0 prio 1 u32"

delayLevel1 () {
	echo "DELAY_LEVEL1 INIT"

	#delay packets for DELAYTIME
	$TC qdisc add dev $IF root netem delay $DELAYTIME

	echo "DELAY_LEVEL1 DONE"
}

delayLevel2 () {
	echo "DELAY_LEVEL2 INIT"

	#delay packets for DELAYTIME,  [$DELAYTIME-$DISTRIBUTION, $DELAYTIME+$DISTRIBUTION]
	$TC qdisc add dev $IF root netem delay $DELAYTIME $DISTRIBUTION

	echo "DELAY_LEVEL2 DONE"
}

delayLevel3 () {
	echo "DELAY_LEVEL3 INIT"

	#delay packets for DELAYTIME, 
	$TC qdisc add dev $IF root netem delay $DELAYTIME $DISTRIBUTION $PERCENTAGE

	echo "DELAY_LEVEL3 DONE"
}

delayLevel4 () {
	echo "DELAY_LEVEL4 INIT"

	#jitter
	$TC qdisc add dev $IF root netem delay $DELAYTIME $DISTRIBUTION $PERCENTAGE distribution normal

	echo "DELAY_LEVEL4 DONE"
}

clean () {
	$TC qdisc del dev $IF root
}

clean
delayLevel1
#delayLevel2
#delayLevel3
#delayLevel4
