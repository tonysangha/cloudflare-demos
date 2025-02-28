# Magic WAN - GRE

This lab environment will automate the creation of a four site Magic WAN topology using GRE encapsulation as per the diagram below:

![mwan-diagram](./images/mwan-gre-topology.png)

Each site has a Loopback adapter that's designed to mimic a LAN interface, and the network addresses will be used to create static routes in Cloudflare's Magic WAN configuration. The table below lists all the specific IP addresses used.

| Site      | Loopback Adapter  | GRE Tunnel VM IP | GRE Tunnel CF IP |
| :-------- | :---------------: | :--------------: | :--------------: |
| Hong Kong | 172.17.255.251/32 | 10.10.10.100/31  | 10.10.10.101/31  |
| Mumbai    | 172.17.255.252/32 | 10.10.10.102/31  | 10.10.10.103/31  |
| Sydney    | 172.17.255.253/32 | 10.10.10.104/31  | 10.10.10.105/31  |
| Tokyo     | 172.17.255.254/32 | 10.10.10.106/31  | 10.10.10.107/31  |

## Automation

This lab is automated end to end using Terraform with configuration being done at Cloudflare, IaaS (GCP) and VM layers. The specifics of the automation are as follows:

- Create four VMs in separate GCP regions using the [Standard Network Tier](https://cloud.google.com/network-tiers)
- Configure GCP VPC Firewall Rules to only allow GRE ingress/egress to [Cloudflare IPs](https://www.cloudflare.com/en-gb/ips/)
- Configure [GRE Tunnel Endpoints](https://developers.cloudflare.com/magic-wan/configuration/manually/how-to/configure-tunnels/) in Cloudflare
- Configure [Static Routes](https://developers.cloudflare.com/magic-wan/configuration/manually/how-to/configure-static-routes/) in Cloudflare
- Automate the configuration of Ubuntu 24.04 LTS VM's

## Lab Environment

Below is a list of useful commands to validate VMs can ping each other, and perform packet captures.

- `whereami` - Confirm Public IP information using IP data
- `showtunnel` - Show GRE Tunnel Details
- `showicmp` - Perform TCP Dump on GRE Interface to show incoming packets from other sites
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

## Packet Flow

The following sequence diagram depicts the packet flow between two loopback adapters. 

```mermaid
sequenceDiagram
    participant Client as Hong Kong - Loopback (172.17.255.251)
    participant VMa as Hong Kong VM
    participant CFa as Cloudflare Anycast Network
    participant VMb as Mumbai VM
    participant Server as Mumbai Loopback (172.17.255.252)
    
    Note over Client,Server: Cross-Site Communication Flow
    
    Client->>VMa: 1. IP Packet to 172.17.255.252
    Note right of VMa: Route lookup: Next hop is<br/>GRE tunnel to Cloudflare
    VMa->>CFa: 2. GRE Encapsulated Packet<br/>(src: 10.10.10.100, dst: 10.10.10.101)
    Note right of CFa: Magic WAN Policy Processing<br/>Route lookup: Next hop is<br/>GRE tunnel to Mumbai
    CFa->>VMb: 3. GRE Encapsulated Packet<br/>(src: 10.10.10.103, dst: 10.10.10.102)
    Note right of VMb: Decapsulate GRE Packet<br/>Route lookup: Next hop is<br/>local loopback
    VMb->>Server: 4. Original IP Packet Delivered
    
    Server-->>VMb: 5. Response Packet to 172.17.255.251
    VMb-->>CFa: 6. GRE Encapsulated Response
    CFa-->>VMa: 7. GRE Encapsulated Response
    VMa-->>Client: 8. Original Response Delivered
```

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

#### Deployment Architecture

A visual representation of the deployment architecture is as follows:

```mermaid
graph TD
    subgraph "Magic WAN Deployment"
        TF[Terraform CLI] -->|Provisions| GCP
        TF -->|Configures| CF[Cloudflare Magic WAN]
        TF -->|Creates| FW[Firewall Rules]
    end
    
    subgraph "GCP Resources"
        GCP -->|Creates| VM1[Hong Kong VM]
        GCP -->|Creates| VM2[Mumbai VM]
        GCP -->|Creates| VM3[Sydney VM]
        GCP -->|Creates| VM4[Tokyo VM]
        FW -->|Protects| VM1
        FW -->|Protects| VM2
        FW -->|Protects| VM3
        FW -->|Protects| VM4
    end
    
    subgraph "VM Configuration"
        VM1 -->|Configured by| Script1[cloud-rtr.tpl]
        VM2 -->|Configured by| Script2[cloud-rtr.tpl]
        VM3 -->|Configured by| Script3[cloud-rtr.tpl]
        VM4 -->|Configured by| Script4[cloud-rtr.tpl]
        
        Script1 -->|Creates| LO1[Loopback Interface]
        Script1 -->|Creates| GRE1[GRE Tunnel]
        Script2 -->|Creates| LO2[Loopback Interface]
        Script2 -->|Creates| GRE2[GRE Tunnel]
        Script3 -->|Creates| LO3[Loopback Interface]
        Script3 -->|Creates| GRE3[GRE Tunnel]
        Script4 -->|Creates| LO4[Loopback Interface]
        Script4 -->|Creates| GRE4[GRE Tunnel]
    end
    
    subgraph "Cloudflare Magic WAN"
        CF -->|Creates| CFT1[GRE Tunnel 1]
        CF -->|Creates| CFT2[GRE Tunnel 2]
        CF -->|Creates| CFT3[GRE Tunnel 3]
        CF -->|Creates| CFT4[GRE Tunnel 4]
        CF -->|Configures| CFSR[Static Routes]
        CF -->|Enables| CFHC[Health Checks]
    end
    
    GRE1 <-->|Establishes| CFT1
    GRE2 <-->|Establishes| CFT2
    GRE3 <-->|Establishes| CFT3
    GRE4 <-->|Establishes| CFT4

    %% Define styles
    classDef terraformClass fill:#e7f5fe,stroke:#4a86e8,stroke-width:2px;
    classDef gcpClass fill:#f1f8e9,stroke:#7cb342,stroke-width:2px;
    classDef vmClass fill:#fff8e1,stroke:#ffb74d,stroke-width:2px;
    classDef cfClass fill:#fff3e0,stroke:#f38020,stroke-width:2px;
    classDef tunnelClass fill:#e3f2fd,stroke:#2196f3,stroke-width:1px;
    
    %% Apply styles
    class TF,FW terraformClass;
    class GCP,VM1,VM2,VM3,VM4 gcpClass;
    class Script1,Script2,Script3,Script4,LO1,LO2,LO3,LO4 vmClass;
    class CF,CFSR,CFHC cfClass;
    class GRE1,GRE2,GRE3,GRE4,CFT1,CFT2,CFT3,CFT4 tunnelClass;
    
    %% Define link styles
    linkStyle 0 stroke:#4a86e8,stroke-width:2px;
    linkStyle 1 stroke:#4a86e8,stroke-width:2px;
    linkStyle 2 stroke:#4a86e8,stroke-width:2px;
    
    linkStyle 3 stroke:#7cb342,stroke-width:2px;
    linkStyle 4 stroke:#7cb342,stroke-width:2px;
    linkStyle 5 stroke:#7cb342,stroke-width:2px;
    linkStyle 6 stroke:#7cb342,stroke-width:2px;
    
    linkStyle 7 stroke:#ffb74d,stroke-width:2px;
    linkStyle 8 stroke:#ffb74d,stroke-width:2px;
    linkStyle 9 stroke:#ffb74d,stroke-width:2px;
    linkStyle 10 stroke:#ffb74d,stroke-width:2px;
    
    linkStyle 11 stroke:#ffb74d,stroke-width:1.5px,stroke-dasharray:5 5;
    linkStyle 12 stroke:#ffb74d,stroke-width:1.5px,stroke-dasharray:5 5;
    linkStyle 13 stroke:#ffb74d,stroke-width:1.5px,stroke-dasharray:5 5;
    linkStyle 14 stroke:#ffb74d,stroke-width:1.5px,stroke-dasharray:5 5;
    linkStyle 15 stroke:#ffb74d,stroke-width:1.5px,stroke-dasharray:5 5;
    linkStyle 16 stroke:#ffb74d,stroke-width:1.5px,stroke-dasharray:5 5;
    linkStyle 17 stroke:#ffb74d,stroke-width:1.5px,stroke-dasharray:5 5;
    linkStyle 18 stroke:#ffb74d,stroke-width:1.5px,stroke-dasharray:5 5;
    
    linkStyle 19 stroke:#f38020,stroke-width:2px;
    linkStyle 20 stroke:#f38020,stroke-width:2px;
    linkStyle 21 stroke:#f38020,stroke-width:2px;
    linkStyle 22 stroke:#f38020,stroke-width:2px;
    linkStyle 23 stroke:#f38020,stroke-width:2px;
    linkStyle 24 stroke:#f38020,stroke-width:2px;
    
    linkStyle 25 stroke:#2196f3,stroke-width:3px;
    linkStyle 26 stroke:#2196f3,stroke-width:3px;
    linkStyle 27 stroke:#2196f3,stroke-width:3px;
    linkStyle 28 stroke:#2196f3,stroke-width:3px;
```