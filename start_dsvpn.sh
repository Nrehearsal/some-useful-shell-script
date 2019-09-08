#!/bin/bash

#dsvpn server address
vpn_server=""
#dsvpn port
vpn_port=""
#dsvpn bin file
vpn_bin=""
#dsvpn key file
vpn_key=""
#ip for dsvpn server
vpn_gw=""
#ip for dsvpn local
vpn_ip=""
#dsvpn tun name, default tun0
tun_name=""
#default gateway for local
default_gw=`ip route show | grep "default via" | awk -F ' ' '{print $3}'`
#default gateway interface for local
default_dev=`ip route show | grep "default via" | awk -F ' ' '{print $5}'`

echo [vpn_server]:$vpn_server
echo [vpn_port]:$vpn_port
echo [vpn_gw]:$vpn_gw
echo [vpn_ip]:$vpn_ip
echo [default_gw]:$default_gw

vpn_cmd="nohup $vpn_bin client $vpn_key $vpn_server $vpn_port $tun_name $vpn_ip $vpn_gw $default_gw >> /dev/null"
echo [vpn_cmd]:$vpn_cmd
$vpn_cmd &

#waitting for dsvpn setup done.
sleep 1

route_for_vpn_server="ip route add $vpn_server via $default_gw dev $default_dev"
route_all_through_vpn1="ip route add 0.0.0.0/1 via $vpn_gw dev $tun_name"
route_all_through_vpn2="ip route add 128.0.0.0/1 via $vpn_gw dev $tun_name"

exist=`ip route show $vpn_server | wc -l`
if [ $exist -eq 0 ]
then
	echo [route]:$route_for_vpn_server
	$route_for_vpn_server
fi

echo [route]:$route_all_through_vpn1
$route_all_through_vpn1

echo [route]:$route_all_through_vpn2
$route_all_through_vpn2
