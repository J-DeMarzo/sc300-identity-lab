# SDN configuration

Desired state of the lab network, so it can be rebuilt. Files are applied by an administrator with SDN permissions; automation tokens in this homelab intentionally cannot allocate SDN.

`sdn.sh` creates the zone, vnet, and subnet with `pvesh` and applies the config. Re-running it fails on existing objects, so check the live state first. DHCP is deliberately not configured in the SDN: the lab DC serves it ([ADR 0002](../docs/adr/0002-dc-serves-dhcp.md)).

```
pvesh get /cluster/sdn/zones
pvesh get /cluster/sdn/vnets
pvesh get /cluster/sdn/vnets/<vnet>/subnets
```
