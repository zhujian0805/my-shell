#!/bin/bash - 

awk 'BEGIN { \
        while(getline < "a.txt"){
            ha[$0]++;
        };
        while(getline < "b.txt"){
            hb[$0]++
        };
        print "IP\t\ta.txt\tb.txt";
        for(k in ha){
            hf[k]++;
        }
        for(k in hb){
            hf[k]++;
        }
        for(k in hf){
            if(k in ha){
                if(k in hb){
                    print k, "\t" ha[k] "\t" hb[k];
                }
            }
        }
    }'
