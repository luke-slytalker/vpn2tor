#!/bin/bash

#############################################
# check to make sure we are running as root #
#############################################
if [ $(whoami) != "root" ]; then
    echo "Must be run as root"
    exit 1
elif ( ! dpkg-query --list openvpn | grep -q "ii"); then
    echo "Please install OpenVPN to your system."
    exit 1
    
elif ( ! dpkg-query --list tor | grep -q "ii"); then
    echo "Tor not installed on your system."
    echo " -- Installing Tor..."
    apt install tor -y
    sleep 2
    
elif ( ! systemctl is-active --quiet openvpn 2>/dev/null); then
    echo "OpenVPN server is not running. Please start OpenVPN service and try again!"
    exit 1
fi


#########################################
# figure out where/what stuff is called #
#########################################
OVPN=$(ip r | grep "tun" | awk '{print $3}')
# usually:  tun0

VPN_IP=$(ip r | grep "tun" | awk '{print $9}')  
# usually:  10.8.0.1

echo "----- HERE ARE THE SETTINGS... ---"
echo "Adapter:  $OVPN"
echo "IP Addr:  $VPN_IP"
echo ""
echo " -- Modifying TOR Configuration... (/etc/tor/torrc)"


#############################################
# add to TOR configuration (/etc/tor/torrc) #
############################################# 
echo "" >> /etc/tor/torrc
echo "VirtualAddrNetwork 10.192.0.0/10" >> /etc/tor/torrc
echo "AutomapHostsOnResolve 1" >> /etc/tor/torrc
echo "DNSPort 10.8.0.1:53530" >> /etc/tor/torrc
echo "TransPort 10.8.0.1:9040" >> /etc/tor/torrc

sleep 1

echo " -- Restarting the TOR service..."

##################################
# restart the tor service so our #
# new settings will take effect  #
##################################

service tor restart

sleep 1 

echo "OpenVPN and Tor are configured."
echo "You can route VPN traffic through Tor or clearnet by running ./vpn2tor.sh"

