#!/bin/awk -f


BEGIN {
	TIMESTAMP=0
	STACKINDEX=0
}

{
	gsub(/:/, "", $4);
	gsub(/\./, "", $4);
	

	if( $0 ~ /myprobe/ ){

		gsub(/+.*/, "",$6);
		gsub(/\(/, "", $6);
		
		FUNCTIONNAME=$6
		TIMESTAMP=$4

		TARRAY[STACKINDEX]=TIMESTAMP
		FARRAY[STACKINDEX]=FUNCTIONNAME
		STACKINDEX++
		
	}else if( $0 ~ /myretprobe/ ){
		gsub(/)/, "", $8);

		RETFUNCTIONNAME=$8
		
		while(STACKINDEX >= 0){
			STACKINDEX--
			if(RETFUNCTIONNAME == FARRAY[STACKINDEX]){
				RETPRO=int($4)
				PRO=int(TARRAY[STACKINDEX])
				#PRO=int(TIMESTAMP)
				RESULT=int(RETPRO-PRO)
				#print STACKINDEX
				break
			}

		}
		###################################################
		# 	calculate difference of timestamp         #
		###################################################

		#RETPRO=int($4)
		#PRO=int(TIMESTAMP)
		#RESULT=int(RETPRO-PRO)
		if ( RESULT >= DELAYTIME ){
			gsub(/\(/, "", $6);
			print RESULT/1000,"ms","\t",$6,$7,$8
		}
	}
}
