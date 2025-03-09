# IPsec and Cloudflare Daemon Tunnel Setup Script
# 
# Description: This script configures a StrongSwan IPsec tunnel to Cloudflare
#              and sets up a Cloudflare Tunnel for secure remote access using SSH.
#
# Prerequisites:
#   - Ubuntu/Debian-based system
#   - Root privileges
#   - Required variables (listed below)
#
# Usage: Used as part of startup-script
#
# Required variables (provided by Terraform):
#   - loopback_addr: IP address for loopback interface
#   - cf_endpoint: Cloudflare Anycast IP
#   - vm_int_addr: VM internal address for VTI
#   - cf_int_addr: Cloudflare internal address for VTI
#   - psk: Pre-shared key for IPsec
#   - account_id: Cloudflare account ID
#   - api_key: Cloudflare API key
#   - email: Cloudflare account email
#   - tunnel_name: Name of the IPsec tunnel
#   - cfd_tunnel_id: Cloudflare Tunnel ID
#   - cfd_tunnel_name: Cloudflare Tunnel name
#   - cfd_secret: Cloudflare Tunnel secret
#   - dns_record: DNS record for Cloudflare Tunnel
#   - cfd_ssh_ca_cert: Cloudflare SSH CA certificate

##############################################
# 0. System Preparation and Alias Configuration
##############################################

# BASH Aliases for all users
echo 'alias log="sudo journalctl -o cat -f _SYSTEMD_UNIT=google-startup-scripts.service"' >> /etc/profile.d/00-aliases.sh
echo 'alias fulllog="sudo journalctl -xefu google-startup-scripts -f"' >> /etc/profile.d/00-aliases.sh
echo 'alias whereami="curl ipinfo.io"' >> /etc/profile.d/00-aliases.sh
echo 'alias showtunnel="sudo ip xfrm state"' >> /etc/profile.d/00-aliases.sh
echo 'alias showroute="sudo ip xfrm policy"' >> /etc/profile.d/00-aliases.sh
echo 'alias showipsec="sudo ipsec statusall"' >> /etc/profile.d/00-aliases.sh
echo 'alias reloadipsec="sudo ipsec reload"' >> /etc/profile.d/00-aliases.sh
echo 'alias restartipsec="sudo ipsec restart"' >> /etc/profile.d/00-aliases.sh

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/local/sbin:/usr/sbin:/sbin:$PATH"

##############################################
# 1. Dynamic MOTD Configuration
##############################################

# Create a custom dynamic MOTD script
cat > /etc/update-motd.d/99-custom-motd << "EOF"
#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# IP Table Colours
HEADER_COLOR='\033[1;36m'  # Bold Cyan
BORDER_COLOR='\033[0;34m'  # Blue
IFACE_COLOR='\033[0;92m'   # High Intensity Green
IP_COLOR='\033[0;93m'      # High Intensity Yellow

printf "$${BLUE}*******************************************$${NC}\n"
printf "$${BLUE}*                                         *$${NC}\n"
printf "$${BLUE}*  WELCOME TO THE CLOUDFLARE TUNNEL HOST  *$${NC}\n"
printf "$${BLUE}*                                         *$${NC}\n"

# Check tunnel status
if ipsec status | grep -q "ESTABLISHED"; then
    printf "$${BLUE}*  $${GREEN}• IPsec Tunnel: CONNECTED$${BLUE}             *$${NC}\n"
else
    printf "$${BLUE}*  $${RED}• IPsec Tunnel: DISCONNECTED$${BLUE}         *$${NC}\n"
fi

if systemctl is-active --quiet cloudflared; then
    printf "$${BLUE}*  $${GREEN}• Cloudflare Tunnel: RUNNING$${BLUE}          *$${NC}\n"
else
    printf "$${BLUE}*  $${RED}• Cloudflare Tunnel: STOPPED$${BLUE}          *$${NC}\n"
fi

printf "$${BLUE}*                                         *$${NC}\n"
printf "$${BLUE}*  Helpful aliases:                       *$${NC}\n"
printf "$${BLUE}*    • showipsec  • reloadipsec           *$${NC}\n"
printf "$${BLUE}*    • whereami   • restartipsec          *$${NC}\n"
printf "$${BLUE}*                                         *$${NC}\n"
printf "$${BLUE}*******************************************$${NC}\n"

# Show system info
printf "\n"
printf "System information:\n"
printf "-------------------\n"
printf "Hostname: $(hostname)\n"
printf "Kernel:   $(uname -r)\n"
printf "Uptime:   $(uptime -p)\n"

# Display network interfaces in a table format
printf "\n"
printf "Network interfaces:\n"
printf "-------------------\n"
echo -e "$${BORDER_COLOR}+-----------------+-----------------+$${NC}"
echo -e "$${BORDER_COLOR}|$${NC} $${HEADER_COLOR}Interface       $${NC}$${BORDER_COLOR}|$${NC} $${HEADER_COLOR}IPv4 Address    $${NC}$${BORDER_COLOR}|$${NC}"
echo -e "$${BORDER_COLOR}+-----------------+-----------------+$${NC}"
ip -4 -o addr show | awk -v iface_color="$${IFACE_COLOR}" -v ip_color="$${IP_COLOR}" -v border="$${BORDER_COLOR}" -v nc="$${NC}" '{
    split($4, a, "/");
    printf("%s|%s %s%-15s%s %s|%s %s%-15s%s %s|%s\n", 
           border, nc, iface_color, $2, nc, border, nc, ip_color, a[1], nc, border, nc);
}'
echo -e "$${BORDER_COLOR}+-----------------+-----------------+$${NC}"
EOF

# Make the script executable
chmod +x /etc/update-motd.d/99-custom-motd

# Optionally disable some of the default MOTD scripts that you don't want
if [ -f /etc/update-motd.d/10-help-text ]; then
    chmod -x /etc/update-motd.d/10-help-text
fi

##############################################
# 2. Package Installation
# Installs required dependencies for networking
# and IPsec tunnel configuration
##############################################

apt-get update
apt-get install curl jq net-tools strongswan -y

##############################################
# 3. Networking Configuration - Loopback
##############################################

# Associate IP Address to Loopback
cat > /etc/netplan/99-loopback.yaml << "EOF"
network:
  version: 2
  renderer: networkd
  ethernets:
    lo:
      addresses: [${loopback_addr}]
EOF

# Change permissions of Netplan yaml file's
chmod 600 /etc/netplan/99-loopback.yaml

# Apply the loopback adapter changes
netplan apply

# Restart Networking Service to ensure all sysctl changes are updated
systemctl restart systemd-networkd

##############################################
# 4. StrongSwan Configuration
##############################################

log "Starting IPSec setup..."

# https://developers.cloudflare.com/magic-wan/configuration/manually/third-party/strongswan/

# Modify StrongSwan daemon configuration
# - install_routes=no: Prevents automatic route installation (we'll set up custom routes manually)
# - install_virtual_ip=no: Disables automatic virtual IP assignment
# - delete_rekeyed_delay=150: Sets delay in seconds before deleting old IKE_SAs after rekeying
sed -i '9i install_routes = no' /etc/strongswan.conf
sed -i '10i install_virtual_ip = no' /etc/strongswan.conf
sed -i '11i delete_rekeyed_delay = 150' /etc/strongswan.conf

# Configure IPsec with the following settings:
# - IKEv2 for key exchange
# - PSK authentication
# - AES256GCM16 encryption with SHA512 for integrity
cat > /etc/ipsec.conf << "EOF"
# ipsec.conf - strongSwan IPsec configuration file

# Global configuration parameters
config setup
    charondebug="all"     # Enable full debugging output
    uniqueids=yes         # Use unique IDs for each connection

# Default connection parameters applied to all connections
conn %default
    ikelifetime=4h        # How long IKE_SAs should be valid
    rekey=yes             # Automatically rekey connections
    reauth=no             # Don't require reauthentication on rekey
    keyexchange=ikev2     # Use IKEv2 protocol (more secure than IKEv1)
    authby=secret         # Use pre-shared keys for authentication
    dpdaction=restart     # Restart connection if dead peer detected
    closeaction=restart   # Restart connection if closed

# Cloudflare-specific tunnel configuration
conn cloudflare-ipsec
    auto=start            # Automatically start this connection at boot
    type=tunnel           # Create a tunnel between networks
    fragmentation=no      # Disable IP fragmentation for better performance
    forceencaps=no        # Don't force UDP encapsulation
    leftauth=psk          # Use pre-shared key for our side authentication
    left=%any             # Use any available local IP as source
    leftid=LEFTFQDN       # Our tunnel identifier (will be replaced later)
    leftsubnet=0.0.0.0/0  # Source network (all traffic)
    right=${cf_endpoint}  # Cloudflare Anycast IP address
    rightid=${cf_endpoint}# Cloudflare identifier
    rightsubnet=0.0.0.0/0 # Destination network (all traffic)
    rightauth=psk         # Use pre-shared key for Cloudflare auth
    ike=aes256gcm16-prfsha512-modp2048  # IKE crypto parameters (encryption-PRF-DH)
    esp=aes256gcm16-prfsha512-modp2048  # ESP crypto parameters (data protection)
    replay_window=0       # Disable anti-replay protection (Cloudflare requirement)
    mark_in=42            # Packet mark for incoming traffic (used by VTI)
    mark_out=42           # Packet mark for outgoing traffic (used by VTI)
    leftupdown=/etc/strongswan.d/ipsec-vti.sh  # Script to create VTI interface
EOF

# Create Virtual Tunnel Interface (VTI) setup script
# This script creates a virtual tunnel interface when the IPsec connection is established
# and removes it when the connection goes down
cat > /etc/strongswan.d/ipsec-vti.sh << "EOF"
#!/bin/bash
set -o nounset    # Exit when script tries to use undeclared variables
set -o errexit    # Exit when command fails

# Store IP command path to variable for easier use
IP=$(which ip)

# Parse the PLUTO_MARK variables to get the first component
# These marks come from the IPsec configuration and are used for the VTI interface
PLUTO_MARK_OUT_FIRST=$${PLUTO_MARK_OUT%%/*}  # Extract first part of outbound mark
PLUTO_MARK_IN_FIRST=$${PLUTO_MARK_IN%%/*}    # Extract first part of inbound mark

# Update the following variables
VTI_IF="vti0"                     # Name of the virtual tunnel interface
VTI_LOCAL_IP="${vm_int_addr}"     # Local IP for the tunnel interface (our side)
VTI_REMOTE_IP="${cf_int_addr}"    # Remote IP for the tunnel interface (Cloudflare side)
ETH_INTF="ens4"                   # Physical network interface name

# Handle different IPsec events
case "$${PLUTO_VERB}" in
     up-client)
        # When tunnel comes up:

        # 1. Create the VTI interface
        #    - local: Our public IP (PLUTO_ME is set by StrongSwan)
        #    - remote: Cloudflare's IP (PLUTO_PEER is set by StrongSwan)
        #    - okey/ikey: Mark values for outbound/inbound traffic
        $IP link add $${VTI_IF} type vti local $${PLUTO_ME} remote $${PLUTO_PEER} okey $${PLUTO_MARK_OUT_FIRST} ikey $${PLUTO_MARK_IN_FIRST}
        
        # 2. Configure IP addressing on the tunnel
        $IP addr add $${VTI_LOCAL_IP} remote $${VTI_REMOTE_IP} dev $${VTI_IF}

        # 3. Set MTU to 1436 (standard for VTI interfaces over IPsec) and bring interface up
        $IP link set $${VTI_IF} up mtu 1436
        
        # 4. Configure kernel networking parameters
        #    - Enable IP forwarding for routing between interfaces
        sysctl -w net.ipv4.ip_forward=1
        
        #    - Disable IPsec policy checks on VTI interface (already handled by tunnel)
        sysctl -w "net.ipv4.conf.$${VTI_IF}.disable_policy=1"
        
        #    - Allow packets from/to same interface (required for some routing scenarios)
        sysctl -w "net.ipv4.conf.$${VTI_IF}.accept_local=1"
        
        #    - Disable reverse path filtering (prevents dropping asymmetrically routed packets)
        sysctl -w "net.ipv4.conf.$${VTI_IF}.rp_filter=0"
        
        #    - Same settings for physical interface to ensure consistency
        sysctl -w "net.ipv4.conf.$${ETH_INTF}.accept_local=1"
        sysctl -w "net.ipv4.conf.$${ETH_INTF}.rp_filter=0"
        
        # 5. Add specific routes through the tunnel interface
        # Each subnet represents different network segments that should go through Cloudflare
        ip route add 10.10.10.0/24 dev $${VTI_IF}    # Tunnel interface address subnet
        ip route add 172.17.255.0/24 dev $${VTI_IF}  # Loopback address subnet
        ip route add 100.96.0.0/12 dev $${VTI_IF}    # Cloudflare WARP client address range
        ;;
        
     down-client)
        # When tunnel goes down:
        
        # 1. Remove all routes that were added through the tunnel
        #    (must be done before removing the interface)
        ip route del 10.10.10.0/24 dev $${VTI_IF}    # Remove tunnel subnet route
        ip route del 172.17.255.0/24 dev $${VTI_IF}  # Remove loopback subnet route
        ip route del 100.96.0.0/12 dev $${VTI_IF}    # Remove WARP subnet route
        
        # 2. Remove the VTI interface completely
        ip tunnel del "$${VTI_IF}"
        ;;
esac
EOF

#Make the script executable
chmod +x /etc/strongswan.d/ipsec-vti.sh

# Add the secret to the ipsec.secrets file
# https://wiki.strongswan.org/projects/strongswan/wiki/Ipsecsecrets

cat > /etc/ipsec.secrets << "EOF"
# This file holds shared secrets or RSA private keys for authentication.

# RSA private key for this host, authenticating it to any other host
# which knows the public part.

: PSK "${psk}"
EOF

# find fqdn ID for tunnel
output=$(curl --request GET \
  --url https://api.cloudflare.com/client/v4/accounts/${account_id}/magic/ipsec_tunnels \
  --header 'Content-Type: application/json' \
  --header "X-Auth-Key: ${api_key}" \
  --header "X-Auth-Email: ${email}" | jq -r ".result.ipsec_tunnels[] | select(.name==\"${tunnel_name}\") | .remote_identities.fqdn_id")

# replace placeholder value with tunnel id
sed -i "s/LEFTFQDN/$output/" /etc/ipsec.conf

# clear variable from memory
unset output

# Enable and start Strongswan to start at boot
systemctl enable strongswan-starter
systemctl start strongswan-starter

# Go through enablement of IPSec Tunnel
ipsec down cloudflare-ipsec
ipsec reload
ipsec restart
ipsec up cloudflare-ipsec

log "Successfully configured IPSec tunnel"

##############################################
# 5. Cloudflare Daemon - Tunnel Configuration
##############################################

log "Starting Cloudflare Tunnel setup..."

# Download and install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared-linux-amd64.deb

# Clean up the downloaded package
rm -f cloudflared-linux-amd64.deb

# A local user directory is first created before we can install the tunnel as a system service

mkdir ~/.cloudflared
touch ~/.cloudflared/cert.json
touch ~/.cloudflared/config.yml

# Another here file is used to dynamically populate the JSON credentials file

cat > ~/.cloudflared/cert.json << "EOF"
{
    "AccountTag"   : "${account_id}",
    "TunnelID"     : "${cfd_tunnel_id}",
    "TunnelName"   : "${cfd_tunnel_name}",
    "TunnelSecret" : "${cfd_secret}"
}
EOF

# Same concept with the Ingress Rules the tunnel will use

cat > ~/.cloudflared/config.yml << "EOF"
tunnel: ${cfd_tunnel_id}
credentials-file: /etc/cloudflared/cert.json
logfile: /var/log/cloudflared.log
loglevel: info

ingress:
  - hostname: ${dns_record}
    service: ssh://localhost:22
  - hostname: "*"
    path: "^/_healthcheck$"
    service: http_status:200
  - hostname: "*"
    service: hello-world
EOF

# Set proper permissions for Cloudflare credentials
chmod 600 ~/.cloudflared/cert.json
chmod 600 ~/.cloudflared/config.yml

# Now we install the tunnel as a systemd service
cloudflared service install
# The credentials file does not get copied over so we'll do that manually
cp -via ~/.cloudflared/cert.json /etc/cloudflared/

cd /tmp

service cloudflared start

log "Successfully installed and started Cloudflare Tunnel"

##############################################
# 6. Secure Shell Configuration
##############################################

cat > /etc/ssh/ca.pub << "EOF"
${cfd_ssh_ca_cert}
EOF

sed -i 's/#PubkeyAuthentication/PubkeyAuthentication/' /etc/ssh/sshd_config
sed -i '$ a TrustedUserCAKeys /etc/ssh/ca.pub' /etc/ssh/sshd_config
systemctl restart ssh

log "SSH setup completed successfully"