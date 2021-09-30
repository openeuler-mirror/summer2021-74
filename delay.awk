#!/bin/awk -f


BEGIN {
	#DELAYTIME=10000
	TIMESTAMP=0
}

{
	# modify the format of timestamp (delete '.' and ':')
	gsub(/:/, "", $4);
	gsub(/\./, "", $4);


	if( $0 ~ /myretprobe/ ){

		gsub(/arg1=/, "", $9);
		SKBADDR=$9
		TIMESTAMP=$4

		ADDRTIMEMAP["${SKBADDR}"]=TIMESTAMP

	} else if( $0 ~ /myprobe/ ){

		gsub(/arg1=/, "", $7);
		SKBADDR=$7
		TIMESTAMP=$4

		if("${SKBADDR}" in ADDRTIMEMAP){
			PRO=int(TIMESTAMP)
			RETPRO=int(ADDRTIMEMAP["${SKBADDR}"])
			RESULT=int(PRO-RETPRO)

			FUNCTIONNAME=$6
			ADDRTIMEMAP["${SKBADDR}"]=TIMESTAMP

			if ( RESULT >= DELAYTIME ){
				if( FUNCTIONNAME ~ /udp_send_skb/ ){
					print "skb address:",SKBADDR," ip_make_skb -> udp_send_skb","\t\t "RESULT/1000,"ms"
				} else if ( FUNCTIONNAME ~ /dev_queue_xmit/ ){
					print "skb address:",SKBADDR," udp_send_skb -> dev_queue_xmit","\t",RESULT/1000,"ms"
				} else if ( FUNCTIONNAME ~ /xmit_one/ ){
					print "skb address:",SKBADDR," dev_queue_xmit -> xmit_one","\t\t "RESULT/1000,"ms"
				}
			}
		}
	}
}
