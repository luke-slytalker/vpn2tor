#!/bin/bash

### make sure we're running as r0ot & everything is installed already..
if [ $(whoami) != "root" ]; then
    echo "Must be run as root"
    exit 1
elif ( ! dpkg-query --list openvpn | grep -q "ii"); then
    echo "Please install OpenVPN to your system."
    exit 1
elif ( ! dpkg-query --list tor | grep -q "ii"); then
    echo "Please install Tor to your system."
    exit 1
elif ( ! systemctl is-active --quiet openvpn 2>/dev/null); then
    echo "OpenVPN server is not running. Please start OpenVPN service and try again!"
    exit 1
fi

### grab some info and set some variables for an easier time..
IPTABLES=$(which iptables)  # /sbin/iptables
OVPN=$(ip r | grep "tun" | awk '{print $3}')  # usually tun0
VPN_IP=$(ip r | grep "tun" | awk '{print $9}')  # usually 10.8.0.1

function route() {
    local arg=$1
    ### Config iptables to route all traffic trough Tor proxy
    # transparent Tor proxy
    $IPTABLES $arg INPUT -i $OVPN -s 10.8.0.0/24 -m state --state NEW -j ACCEPT
    $IPTABLES -t nat $arg PREROUTING -i $OVPN -p udp --dport 53 -s 10.8.0.0/24 -j DNAT --to-destination $VPN_IP:53530
    $IPTABLES -t nat $arg PREROUTING -i $OVPN -p tcp -s 10.8.0.0/24 -j DNAT --to-destination $VPN_IP:9040
    $IPTABLES -t nat $arg PREROUTING -i $OVPN -p udp -s 10.8.0.0/24 -j DNAT --to-destination $VPN_IP:9040

    ### Transproxy leak blocked:
    # https://trac.torproject.org/projects/tor/wiki/doc/TransparentProxy#WARNING
    $IPTABLES $arg OUTPUT -m conntrack --ctstate INVALID -j DROP
    $IPTABLES $arg OUTPUT -m state --state INVALID -j DROP
    $IPTABLES $arg OUTPUT ! -o lo ! -d 127.0.0.1 ! -s 127.0.0.1 -p tcp -m tcp --tcp-flags ACK,FIN ACK,FIN -j DROP
    $IPTABLES $arg OUTPUT ! -o lo ! -d 127.0.0.1 ! -s 127.0.0.1 -p tcp -m tcp --tcp-flags ACK,RST ACK,RST -j DROP
}

### check if the iptables rules are already in effect...
###   - if rules ARE in effect, this will stop Tor and clear the routes.
###   - if rules are NOT in effect, this will START Tor and set the routes.
if ($IPTABLES --check INPUT -i $OVPN -s 10.8.0.0/24 -m state --state NEW -j ACCEPT 2>/dev/null); then
    echo "Stoping Tor and removing iptables routes.."
    systemctl stop tor
    route "-D"
    echo "Done."
else
    echo "Starting Tor and adding iptables routes..."
    systemctl start tor
    sleep 3
    route "-A"
    echo "Now you can connect to your VPN and surf on the TOR network"
fi
