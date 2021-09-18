#!/bin/awk -f


BEGIN {
	DELAYTIME=100000
	RECORD=0
}

{
	gsub(/:/, "", $4);
	gsub(/\./, "", $4);
	
	if( $0 ~ /myprobe/ ){
		RECORD=$4
	}else if( $0 ~ /myretprobe/ ){
		RETPRO=int($4)
		PRO=int(RECORD)
		RESULT=int(RETPRO-PRO)
		#print RESULT 
		#RESULT=int($4-$RECORD)
		#print $RESULT
		if ( RESULT >= DELAYTIME )
			print RESULT/1000,"ms","\t",$6,$7,$8
	}
}
