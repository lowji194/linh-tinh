#!/bin/bash
YUM=$(which yum)
#####
if [ "$YUM" ]; then
echo > /etc/sysctl.conf
##
tee -a /etc/sysctl.conf <<EOF
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.all.disable_ipv6 = 0
EOF
##
sysctl -p
IPC=$(curl -4 -s icanhazip.com | cut -d"." -f3)
IPD=$(curl -4 -s icanhazip.com | cut -d"." -f4)
##
if [ $IPC == 4 ]
then
   tee -a /etc/sysconfig/network-scripts/ifcfg-eth0 <<-EOF
	IPV6INIT=yes
	IPV6_AUTOCONF=no
	IPV6_DEFROUTE=yes
	IPV6_FAILURE_FATAL=no
	IPV6_ADDR_GEN_MODE=stable-privacy
	IPV6ADDR=2403:6a40:0:40::$IPD:0000/64
	IPV6_DEFAULTGW=2403:6a40:0:40::1
	EOF
elif [ $IPC == 5 ]
then
   tee -a /etc/sysconfig/network-scripts/ifcfg-eth0 <<-EOF
	IPV6INIT=yes
	IPV6_AUTOCONF=no
	IPV6_DEFROUTE=yes
	IPV6_FAILURE_FATAL=no
	IPV6_ADDR_GEN_MODE=stable-privacy
	IPV6ADDR=2403:6a40:0:41::$IPD:0000/64
	IPV6_DEFAULTGW=2403:6a40:0:41::1
	EOF
elif [ $IPC == 244 ]
then
   tee -a /etc/sysconfig/network-scripts/ifcfg-eth0 <<-EOF
	IPV6INIT=yes
	IPV6_AUTOCONF=no
	IPV6_DEFROUTE=yes
	IPV6_FAILURE_FATAL=no
	IPV6_ADDR_GEN_MODE=stable-privacy
	IPV6ADDR=2403:6a40:2000:244::$IPD:0000/64
	IPV6_DEFAULTGW=2403:6a40:2000:244::1
	EOF
else
	tee -a /etc/sysconfig/network-scripts/ifcfg-eth0 <<-EOF
	IPV6INIT=yes
	IPV6_AUTOCONF=no
	IPV6_DEFROUTE=yes
	IPV6_FAILURE_FATAL=no
	IPV6_ADDR_GEN_MODE=stable-privacy
	IPV6ADDR=2403:6a40:0:$IPC::$IPD:0000/64
	IPV6_DEFAULTGW=2403:6a40:0:$IPC::1
	EOF
fi

service NetworkManager restart

fi
echo 'Da tao IPV6 thanh cong!'
