# ADR 0001: SDN zone type for the isolated lab

**Status:** Accepted
**Date:** 2026-10-14

## Context

The SC-300 lab needs a network that is separate from the home VLANs, has outbound internet (Entra sync and sign-in need HTTPS to Microsoft), and can be torn down and rebuilt without touching physical switching. Proxmox SDN offers several zone types.

The lab has three or four VMs, and the cluster nodes have 8 to 12 threads and 23 to 31 GiB of RAM each, so a single node could be too tight if other guests share it.

## Options

| Zone | Spans nodes | Needs physical config | Notes |
|---|---|---|---|
| Simple | No, one node only | No | Simplest. Built-in SNAT. All lab VMs pinned to one node |
| VXLAN | Yes | No (UDP 4789 between nodes) | Overlay across nodes. Needs an MTU reduction of 50 bytes. SNAT is still done on a node |
| VLAN | Yes | Yes, trunk and router config | Reuses physical network. Defeats the "no physical change" goal |

## Decision

Use a **simple** zone and run every lab VM on **sevro**. The lab is expected to be the DC plus two or three other VMs (sync server and one or two clients). Sevro had about 27 GiB RAM and 317 GiB of `fast-local` free on 2026-10-14, with an idle CPU, which covers that. Move to VXLAN only if one node cannot hold the lab.

## Consequences

- Live migration of lab VMs is not possible. Backups and templates cover recovery instead.
- Egress is SNAT through the node, so [isolation tests](../architecture.md#isolation-tests) T3 to T5 must pass before any real tenant data is synced.
- If VXLAN is chosen later, record the MTU change and the new test results in a follow-up ADR.
