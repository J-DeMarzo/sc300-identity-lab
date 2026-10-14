#!/usr/bin/env bash
# Create the isolated lab network. Run as root on a cluster node.
# Mirrors the live state recorded in docs/architecture.md (checked 2026-10-14).
set -euo pipefail

ZONE=sc900
VNET=sc900
CIDR=10.12.45.0/24
GATEWAY=10.12.45.1
DHCP_START=10.12.45.50
DHCP_END=10.12.45.100

pvesh create /cluster/sdn/zones --zone "$ZONE" --type simple --ipam pve --dhcp dnsmasq
pvesh create /cluster/sdn/vnets --vnet "$VNET" --zone "$ZONE"
pvesh create "/cluster/sdn/vnets/$VNET/subnets" \
  --type subnet --subnet "$CIDR" --gateway "$GATEWAY" --snat 1 \
  --dhcp-range "start-address=$DHCP_START,end-address=$DHCP_END"

# Nothing is active until the SDN config is applied.
pvesh set /cluster/sdn
