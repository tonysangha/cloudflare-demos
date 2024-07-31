# Linux Distribution - Ubuntu 24.04 LTS

# BASH Aliases for all users
echo 'alias log="sudo journalctl -o cat -f _SYSTEMD_UNIT=google-startup-scripts.service"' >> /etc/profile.d/00-aliases.sh
echo 'alias startupscriptlog="sudo journalctl -xefu google-startup-scripts -f"' >> /etc/profile.d/00-aliases.sh
echo 'alias cloudinitlog="tail -f /var/log/cloud-init.log"'  >> /etc/profile.d/00-aliases.sh
echo 'alias whereami="curl ipinfo.io"' >> /etc/profile.d/00-aliases.sh
echo 'alias showtunnel="ip tunnel show"' >> /etc/profile.d/00-aliases.sh
echo 'alias showicmp="sudo tcpdump -i gre2 -n net 172.17.255.0/24 or 10.10.10.0/24"' >> /etc/profile.d/00-aliases.sh

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/local/sbin:/usr/sbin:/sbin:$PATH"

# Install required packages

apt update
apt install net-tools -y

#########################
# Networking Changes
#########################

# Enable IP forwarding
sed -i "s/#net.ipv4.conf.default.rp_filter=1/net.ipv4.conf.default.rp_filter=2/g"  /etc/sysctl.conf
sed -i "s/#net.ipv4.conf.all.rp_filter=1/net.ipv4.conf.all.rp_filter=2/g"  /etc/sysctl.conf
sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g"  /etc/sysctl.conf
echo 'net.ipv4.conf.all.accept_local=1' >> /etc/sysctl.conf
sysctl --system

# Associate IP Address to Loopback
cat > /etc/netplan/99-loopback.yaml << "EOF"
network:
  version: 2
  renderer: networkd
  ethernets:
    lo:
      addresses: [${lo_cidr}]
EOF

# Assign bash variables for internal and public VM addressing
# public_ip=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip" -H "Metadata-Flavor: Google")
local_ip=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip" -H "Metadata-Flavor: Google")

# Create GRE Interface and associate network routes
# Remove quotes around EOF allows for variable expansion 
cat > /etc/netplan/99-gre.yaml << EOF
network:
  version: 2
  tunnels:
    gre1:
      mode: gre
      local: $local_ip  # Local endpoint IP
      remote: ${cf_gre_ip_1}  # Remote endpoint IP
      addresses:
        - ${gre_lcl_cidr}  # IP address for the GRE interface
      routes:
      - to: 172.17.255.0/24
        via: ${gre_next_hop}
      - to: 10.10.10.0/24
        via: ${gre_next_hop}
EOF

# # Change permissions of Netplan yaml file's
chmod 600 /etc/netplan/99-loopback.yaml
chmod 600 /etc/netplan/99-gre.yaml

# # Apply the loopback adapter changes
netplan apply

# # Restart Networking Service to ensure all sysctl changes are updated
systemctl restart systemd-networkd