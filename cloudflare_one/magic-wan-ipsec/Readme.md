# Magic WAN - IPsec

This lab environment will automate the creation of a four site Magic WAN topology using IPsec encapsulation as per the diagram below:

![mwan-diagram](./images/mwan-ipsec-topology.png)

Each site has a Loopback adapter that's designed to mimic a LAN interface, and the network addresses will be used to create static routes in Cloudflare's Magic WAN configuration. The table below lists all the specific IP addresses used.

| Site      | Loopback Adapter  | VTI Tunnel VM IP | VTI Tunnel CF IP |
| :-------- | :---------------: | :--------------: | :--------------: |
| Hong Kong | 172.17.255.251/32 | 10.10.10.100/31  | 10.10.10.101/31  |
| Mumbai    | 172.17.255.252/32 | 10.10.10.102/31  | 10.10.10.103/31  |
| Sydney    | 172.17.255.253/32 | 10.10.10.104/31  | 10.10.10.105/31  |
| Tokyo     | 172.17.255.254/32 | 10.10.10.106/31  | 10.10.10.107/31  |

## Automation

This lab is automated end to end using Terraform with configuration being done at Cloudflare, IaaS (GCP) and VM layers. The specifics of the automation are as follows:

- Create four VMs in separate GCP regions using the [Standard Network Tier](https://cloud.google.com/network-tiers)
- Configure GCP VPC Firewall Rules to only allow IPsec ingress/egress to [Cloudflare IPs](https://www.cloudflare.com/en-gb/ips/)
- Configure [IPsec Tunnel Endpoints](https://developers.cloudflare.com/magic-wan/configuration/manually/how-to/configure-tunnels/) in Cloudflare
- Configure [Static Routes](https://developers.cloudflare.com/magic-wan/configuration/manually/how-to/configure-static-routes/) in Cloudflare
- Automate the configuration of Ubuntu 24.04 LTS VM's with [StrongSwan](https://strongswan.org/) for creating the IPsec tunnels to Cloudflare

# Lab Environment

Below is a list of useful commands to validate VMs can ping each other, and perform packet captures.

- `whereami` - Confirm Public IP information using IP data
- `showipsec` - Show IPsec Connection details
- `showtunnel` - Show IPsec Tunnel Details
- Capture Health Check ICMP Echo Replies only - `sudo tcpdump -i any 'icmp[icmptype] == 0 and not (net 172.17.255.0/24 or net 10.10.10.0/24)'`

## Deploying in your own environment

Prior to deployment, ensure the following pre-reqs have been met:

## Pre-Requisites

- Must have Terraform available locally
- Must have Magic WAN enabled on your Cloudflare account
- Must have at least 1 x Anycast IP assigned to your account by Cloudflare
- Must have access to GCP to deploy VMs to (configurable)

### Deployment

- Copy the `terraform.tfvars.example` to `terraform.tfvars`
- Add missing variables for your environment, lines `1 - 11`
- Initialise the providers `terraform init --upgrade`
- Deploy lab using command `terraform apply`
- Destroy lab using command `terraform destroy`

Once the deployment has succeeded you can `ping` from one VM to another's loopback, and all health checks should also display as healthy in Cloudflare's Dashboard.

![health-checks](./images/successful-health-checks.png)
