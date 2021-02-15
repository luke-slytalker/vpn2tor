# vpn2tor
Some scripts to help setup an OpenVPN server and route the traffic through Tor.

You'll need OpenVPN setup on a server to start.  I use an easy install script from Nyr on GitHub:

`wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh`

After you've installed OpenVPN server and have downloaded your .ovpn cert, you can install Tor and run the tor-setup.sh script.
(This will add a few lines to the torrc file)

After you've got OpenVPN and Tor, you can run vpn2tor.sh and then connect from a client.
Check your IP, and you should be coming from a Tor exit-node.
Run the script again (to turn it off) and check your IP again--you should be coming from your VPN now.


## IPv6 (I haven't tested this part yet)
If you're worried about IPv6 leakage, you can edit the sysctl.conf:

`nano /etc/sysctl.conf`

add this line:

`net.ipv6.conf.all.disable_ipv6 = 1`

then run:

`sysctl -p`




