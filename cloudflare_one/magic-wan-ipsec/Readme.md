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

## Lab Environment

Below is a list of useful commands to validate VMs can ping each other, and perform packet captures.

- `whereami` - Confirm Public IP information using IP data
- `showipsec` - Show IPsec Connection details
- `showtunnel` - Show IPsec Tunnel Details
- Capture Health Check ICMP Echo Replies only - `sudo tcpdump -i any 'icmp[icmptype] == 0 and not (net 172.17.255.0/24 or net 10.10.10.0/24)'`

## Deploying in your own environment

Prior to deployment, ensure the following pre-reqs have been met:

## Pre-Requisites

- Must have Terraform installed locally
- Must have Magic WAN enabled on your Cloudflare account
- Must have at least 1 x Anycast IP assigned to your account by Cloudflare
- Must have access to GCP to deploy VMs to (configurable)
- (Optional) have a Cloudflare R2 bucket setup to be used for Terraform state files
- (Optional) if using R2, ensure the [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) is installed on your system

## State Files

If you do not intend to leverage R2 for state, comment out the following lines in the `providers.tf` file:

```hcl
  # Use Cloudflare R2 to store state file
  backend "s3" {
    bucket                      = ""
    key                         = ""
    region                      = ""
    profile                     = ""
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
```

If you intend on using R2, following the instructions to create a bucket and API keys from [Cloudflare Dev Docs](https://developers.cloudflare.com/terraform/advanced-topics/remote-backend/#create-r2-bucket). Once created, you need also to create a new AWS profile with the following command `aws configure --profile terraform_r2` For region type `auto` and for output type `json`.

Once the profile is configured, update the `state.config` file with your bucket name and profile name if they diverge from what's already there.

### Deployment

- Copy the `terraform.tfvars.example` to `terraform.tfvars`
- Add missing variables for your environment, lines `1 - 9`
- Initialize the providers if not using R2 for state: `terraform init --upgrade`
- Initialize the providers if you are using R2 for state: `terraform init -backend-config="./state.config" -backend-config="endpoint=<ACCOUNT_ID>.r2.cloudflarestorage.com"`
  - Ensure `<ACCOUNT_ID>` is replaced with your Cloudflare Account ID
- Deploy lab using command `terraform apply`
- Destroy lab using command `terraform destroy`

Once the deployment has succeeded you can `ping` from one VM to another's loopback, and all health checks should also display as healthy in Cloudflare's Dashboard.

![health-checks](./images/successful-health-checks.png)
