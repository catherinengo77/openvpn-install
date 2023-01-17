#!/bin/sh
#
# iptables example configuration script
#
# Flush all current rules from iptables
#
# iptables -F
# iptables -t nat -F
# iptables -t mangle -F

#
# Allow SSH connections on tcp port 22 (or whatever port you want to use)
#
# iptables -A INPUT -p tcp --dport 22 -j ACCEPT

#
# Set default policies for INPUT, FORWARD and OUTPUT chains
#
# iptables -P INPUT DROP                #using DROP for INPUT is not always recommended. Change to ACCEPT if you prefer. 
# iptables -P FORWARD ACCEPT
# iptables -P OUTPUT ACCEPT

#
# Set access for localhost
#
# iptables -A INPUT -i lo -j ACCEPT

#
# Accept packets belonging to established and related connections
#
# iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#
#Accept connections on 1194 for vpn access from clients
#Take note that the rule says "UDP", and ensure that your OpenVPN server.conf says UDP too
#
# iptables -A INPUT -p udp --dport 1194 -j ACCEPT
  
#
#Apply forwarding for OpenVPN Tunneling
#
# iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
# iptables -A FORWARD -s 10.8.0.0/24 -j ACCEPT     #10.8.0.0 ? Check your OpenVPN server.conf to be sure
# iptables -A FORWARD -j REJECT
# iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

#
#Enable forwarding
# 
echo 1 > /proc/sys/net/ipv4/ip_forward


#
# Some generally optional rules. Enable and disable these as per your requirements
# 

# Accept traffic with the ACK flag set
# iptables -A INPUT -p tcp -m tcp --tcp-flags ACK ACK -j ACCEPT
# Accept responses to DNS queries
# iptables -A INPUT -p udp -m udp --dport 1024:65535 --sport 53 -j ACCEPT
# Accept responses to our pings
# iptables -A INPUT -p icmp -m icmp --icmp-type echo-reply -j ACCEPT
# Accept notifications of unreachable hosts
# iptables -A INPUT -p icmp -m icmp --icmp-type destination-unreachable -j ACCEPT
# Accept notifications to reduce sending speed
# iptables -A INPUT -p icmp -m icmp --icmp-type source-quench -j ACCEPT
# Accept notifications of lost packets
# iptables -A INPUT -p icmp -m icmp --icmp-type time-exceeded -j ACCEPT
# Accept notifications of protocol problems
# iptables -A INPUT -p icmp -m icmp --icmp-type parameter-problem -j ACCEPT
# Respond to pings
# iptables -A INPUT -p icmp -m icmp --icmp-type echo-request -j ACCEPT
# Accept traceroutes
# iptables -A INPUT -p udp -m udp --dport 33434:33523 -j ACCEPT

# OpenVPN Port  Forwarding rules to port range https://unix.stackexchange.com/questions/366904/redirect-all-ports-to-openvpn-client
iptables -t nat -A PREROUTING -p tcp -m tcp --dport 7000:9000 -j DNAT --to-destination 10.8.0.2
iptables -t filter -A INPUT -p tcp -d 10.8.0.2 --dport 7000:9000 -j ACCEPT
iptables -t nat -A POSTROUTING -j MASQUERADE

# OpenVPN Port  Forwarding rules for specific port
# iptables -t nat -A PREROUTING -p tcp -m tcp --dport 80 -j DNAT --to-destination 10.8.0.2:80
# iptables -t filter -A INPUT -p tcp -d 10.8.0.2 --dport 80 -j ACCEPT


# OpenVPN Port  Forwarding rules for specific port to different port
# iptables -t nat -A PREROUTING -p tcp -m tcp --dport 80 -j DNAT --to-destination 10.8.0.2:81
# iptables -t filter -A FORWARD -d 10.8.0.2 -p tcp -m tcp --dport 80 -j ACCEPT

# OpenVPN Port  Forwarding rules for multiple user https://forums.openvpn.net/viewtopic.php?f=6&t=7823
# PORT = 80
# iptables -A FORWARD -p tcp -i eth0 -d $ifconfig_pool_remote_ip --dport $PORT -j ACCEPT
# iptables -t nat -A PREROUTING -p tcp -d $ifconfig_local --dport $PORT -j DNAT --to-destination $ifconfig_pool_remote_ip:$PORT


# more details here https://whattheserver.com/openvpn-server-with-port-forwarding/

#
# List rules
#
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections

# sudoapt-get -y install iptables-persistent
iptables-save >/etc/iptables/rules.v4
service openvpn restart
iptables -L --line-numbers
