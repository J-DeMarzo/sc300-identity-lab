#!/usr/bin/env bash
# Create the isolated lab network. Run as root on a cluster node.
# No SDN DHCP: the lab DC serves DHCP (ADR 0002).
# Mirrors the live state recorded in docs/architecture.md (created 2026-10-14).
set -euo pipefail

ZONE=sc300
VNET=sc300
CIDR=10.12.41.0/24
GATEWAY=10.12.41.1

pvesh create /cluster/sdn/zones --zone "$ZONE" --type simple
pvesh create /cluster/sdn/vnets --vnet "$VNET" --zone "$ZONE"
pvesh create "/cluster/sdn/vnets/$VNET/subnets" \
  --type subnet --subnet "$CIDR" --gateway "$GATEWAY" --snat 1

# Nothing is active until the SDN config is applied.
pvesh set /cluster/sdn
