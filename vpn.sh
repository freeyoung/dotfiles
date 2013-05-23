#!/bin/bash

opr=$1
vpnip=$(ifconfig tun0 | grep 'inet' | perl -ne 'print $1 if /(1\d+\.\d+\.\d+\.\d+)/')

[ "$opr" == "" ] && exit 2

if [ "$opr" == "on" ]; then

    route add -net 118.144.67.0/24 10.0.0.100
    route delete default
    route add default $vpn_ip 
    
elif [ "$opr" == "off" ]; then

    route delete -net 118.144.67.0/24
    route delete default
    route add default 10.0.0.100

fi
