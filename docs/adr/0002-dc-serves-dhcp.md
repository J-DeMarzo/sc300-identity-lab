# ADR 0002: The lab DC serves DHCP, not the SDN

**Status:** Accepted
**Date:** 2026-10-14

## Context

Proxmox SDN can run DHCP for a subnet using dnsmasq on each node. That needs the `dnsmasq` package installed on every cluster node, and the first attempt to apply the zone warned `cannot reload with missing 'dnsmasq' package` and left the bridge down.

The lab needs a DC with a static address anyway, and a production AD environment normally runs DHCP on a Windows server.

## Decision

SDN DHCP is off. The DC runs the Windows DHCP Server role, authorized in AD, with a scope of `10.12.41.50` to `10.12.41.100`, router `10.12.41.1`, and DNS pointing at the DC. Servers use static addresses in `.2` to `.49`.

## Consequences

- No packages are installed on the Proxmox nodes.
- DHCP and DNS become part of the DC build and appear in the labs as a realistic dependency.
- Clients get no address until the DC is up. A client built before the DC needs a temporary static address.
- DC DNS forwarders must be public resolvers, not the home DNS servers, to keep the boundary intact.
