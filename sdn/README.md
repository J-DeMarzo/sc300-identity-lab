# SDN configuration

Desired state of the lab network, so it can be rebuilt. Files are applied by an administrator with SDN permissions; automation tokens in this homelab intentionally cannot allocate SDN.

`sdn.sh` creates the zone, vnet, and subnet with `pvesh`. It is idempotent only in the sense that re-running it fails on existing objects: check the live state first.

```
pvesh get /cluster/sdn/zones
pvesh get /cluster/sdn/vnets
pvesh get /cluster/sdn/vnets/<vnet>/subnets
```
