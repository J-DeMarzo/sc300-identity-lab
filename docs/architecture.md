# Architecture

## Network

The lab uses Proxmox SDN so its network exists only inside the hypervisor: no VLAN on the physical switch, no changes to the home router.

| Item | Value | Verified |
|---|---|---|
| Zone | `sc900` (type `simple`, IPAM `pve`, DHCP `dnsmasq`) | 2026-10-14, `pvesh get /cluster/sdn/zones` |
| Vnet | `sc900` | 2026-10-14 |
| Subnet | `10.12.45.0/24`, gateway `10.12.45.1`, SNAT on | 2026-10-14 |
| DHCP range | `10.12.45.50` to `10.12.45.100` | 2026-10-14 |

The zone and vnet were created ahead of this repo under an earlier name. Renaming to `sc300` is a recreate (SDN IDs are immutable and limited to 8 characters), tracked in the [roadmap](roadmap.md).

Desired state is kept in [`sdn/`](../sdn/) so the network can be rebuilt.

### Addressing plan

| Range | Use |
|---|---|
| `.1` | SDN gateway (the node) |
| `.2` to `.49` | Static: DC, sync server, servers |
| `.50` to `.100` | DHCP: clients |

## Hosts

| Host | Role | Status |
|---|---|---|
| DC | AD DS and DNS for the lab forest | 🗓️ Planned |
| Sync server | Entra Connect or Cloud Sync agent | 🗓️ Planned |
| Win11 client | Domain join, hybrid join, Intune enrollment | 🗓️ Planned |

Windows images are evaluation editions. Their expiry dates are recorded in the inventory once built.

## Isolation tests

The point of an isolated SDN is that a mistake in this lab cannot reach the home network. SNAT is the weak spot: traffic from the vnet leaves as the node's own address, so it may be treated as trusted host traffic by the home firewall instead of as lab traffic. This is assumed possible until tested.

Method, as with any firewall change: write the test, run it, record the result, then change the rule and run it again.

| # | From | To | Expected | Result |
|---|---|---|---|---|
| T1 | lab guest | internet, TCP 443 | allowed | not run |
| T2 | lab guest | Microsoft sign-in endpoints | allowed | not run |
| T3 | lab guest | Proxmox node management IP, TCP 8006 and 22 | blocked | not run |
| T4 | lab guest | home management VLAN | blocked | not run |
| T5 | lab guest | home server and IoT VLANs | blocked | not run |
| T6 | home VLANs | lab guest | blocked | not run |

If T3 to T5 fail, the fix is a firewall rule at the SDN boundary and a second run showing the change. Both runs go in this table.

## Cross-node placement

A `simple` zone is local to one node: guests on different nodes cannot reach each other. That means every lab VM must run on the same node, or the zone must change to VXLAN. See [ADR 0001](adr/0001-isolated-sdn-zone-type.md).
