#!/bin/sh

netstat -anp|grep ESTAB|awk '
        { \
                fip=$5; \
                sub(":.*", "", fip); \
                foreign_ip[fip]++;
        }
        END{
                for(i in foreign_ip){
                        print i " has " foreign_ip[i] " connections to this server!";
                }
        }'
