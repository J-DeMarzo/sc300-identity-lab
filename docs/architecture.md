# Architecture

## Network

The lab uses Proxmox SDN so its network exists only inside the hypervisor: no VLAN on the physical switch, no changes to the home router.

| Item | Value | Verified |
|---|---|---|
| Zone | `sc300` (type `simple`, no SDN IPAM or DHCP) | 2026-10-14, `pvesh get /cluster/sdn/zones` |
| Vnet | `sc300` | 2026-10-14 |
| Subnet | `10.12.41.0/24`, gateway `10.12.41.1`, SNAT on | 2026-10-14 |
| Bridge | `sc300` is up on darrow, sevro and ragnar, each with `10.12.41.1/24` | 2026-10-14, `ip -br a show sc300` |
| SNAT | `-s 10.12.41.0/24 -o vmbr0 -j SNAT --to-source <node mgmt IP>` | 2026-10-14, `iptables -t nat -S` |

Desired state is kept in [`sdn/`](../sdn/) so the network can be rebuilt. The earlier zone was deleted and recreated with this name and range. Zone IDs are immutable and capped at 8 characters, hence `sc300`.

Because a simple zone is per-node, the same `10.12.41.1` exists on all three nodes as three separate, unconnected segments. Only the node that hosts the lab VMs matters.

### Addressing plan

| Range | Use |
|---|---|
| `.1` | SDN gateway (the node) |
| `.2` to `.49` | Static: DC, sync server, servers |
| `.50` to `.100` | DHCP scope served by the lab DC ([ADR 0002](adr/0002-dc-serves-dhcp.md)) |

## Hosts

| Host | Role | Status |
|---|---|---|
| DC | AD DS, DNS and DHCP for the lab forest, static `10.12.41.2` | 🗓️ Planned |
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
