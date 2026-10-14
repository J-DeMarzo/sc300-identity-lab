# Provision the lab VMs

Builds three plain Windows machines on the isolated `sc300` bridge: `dc01`, `ws01` and `ws02`. They are deliberately **not configured**: no AD DS, DNS or DHCP role, no domain join, no Entra join. Those steps are the exercises.

| VM | VMID | OS | Address (temporary, static) | Disk |
|---|---|---|---|---|
| dc01 | 252 | Windows Server 2025 Standard evaluation (Desktop Experience) | 10.12.41.2 | 60 GB |
| ws01 | 253 | Windows 11 Enterprise evaluation | 10.12.41.11 | 64 GB |
| ws02 | 254 | Windows 11 Enterprise evaluation | 10.12.41.12 | 64 GB |

All run on sevro with 2 cores and 4 GB RAM. The addresses are static because nothing on the network hands out DHCP yet; each machine also gets public DNS (`1.1.1.1`, `9.9.9.9`) and the `10.12.41.1` gateway so it can reach the internet. When the DC takes over DNS and DHCP, change them (`Set-NetIPInterface -InterfaceAlias Ethernet -Dhcp Enabled` and `Set-DnsClientServerAddress -ResetServerAddresses`).

## Build

Run from `ops`. The script needs SSH to sevro and sefi with sudo.

```
scripts/lab-vm up dc01     # create, install, detach media
scripts/lab-vm up ws01
scripts/lab-vm up ws02
scripts/lab-vm status
```

`lab-vm` does the following:
1. Generates the local administrator password once into `~/.config/sc300-lab/admin.pass` on ops (mode 600). It is never printed or committed.
2. Fills the unattended answer file ([server](../../windows/autounattend-server.xml), [client](../../windows/autounattend-client.xml)) with the computer name, address and password, and builds it into a small ISO on sefi.
3. Creates the VM on sevro attached to `sc300`. Server uses SeaBIOS; clients use UEFI with Secure Boot and a virtual TPM 2.0, which Windows 11 requires.
4. Starts it, presses Enter through the "boot from CD" prompt on the clients, and waits for the QEMU guest agent.
5. Detaches the install media and deletes the answer ISO, because that ISO contains the password in plain text.

## Sign in

Console from the Proxmox web UI. The account is `Administrator` on `DC01` and `labadmin` on the clients. The password is in `~/.config/sc300-lab/admin.pass` on ops.

## Reaching the lab from a desktop

The lab network is isolated, so a desktop on a home VLAN has no route to `10.12.41.0/24` and cannot ping or RDP to it directly. That is the design (isolation test T6). Sevro owns the `sc300` bridge, so it can reach every lab VM. Tunnel through it:

```
ssh -N -L 3390:10.12.41.2:3389 -L 3391:10.12.41.11:3389 -L 3392:10.12.41.12:3389 demarzo@sevro
```

Leave that running, then point an RDP client at `localhost:3390` (dc01), `localhost:3391` (ws01) or `localhost:3392` (ws02). The proxmox console in the web UI also always works and needs no network.

Notes:
- RDP is enabled on dc01 (checked 2026-10-14: TCP 3389 answers from sevro). It is not enabled on the Windows 11 clients by default; use the console, or enable it under Settings > System > Remote Desktop.
- Ping to the lab VMs times out even from sevro, because Windows blocks inbound ICMP echo by default. Test with a TCP port instead.
- Do not add a route to `10.12.41.0/24` on the home router. That would put the lab on the home network and defeat the isolation tests.

## Evaluation licenses

Windows Server and Windows 11 evaluation editions expire. Rebuild from this runbook when they do, or re-arm where Microsoft allows it. Expiry read with `slmgr /xpr` on 2026-10-14:

| VM | Expires |
|---|---|
| dc01 | 2027-04-12 |
| ws02 | 2027-01-12 |
| ws01 | not yet reported ("Notification mode"); expect about 2027-01-12. Recheck after a few days |

## Verified after the first build

On 2026-10-14, from inside each VM via the guest agent: the computer name matches, the gateway `10.12.41.1` answers ping, TCP 443 to `login.microsoftonline.com` connects, and `PartOfDomain` is false. This is only a smoke test. The isolation tests in [architecture](../architecture.md#isolation-tests) have **not** been run.

First-boot note: the guest agent answers before Windows finishes its first-logon commands, so the static address can appear about a minute after the agent does.

## Reset

Each VM has a snapshot named `clean-install`, taken 2026-10-14 right after the first build (workgroup, no roles, no RAM state). Roll back with `qm rollback <vmid> clean-install` on sevro or from the Proxmox UI. A rollback restores the disk only, so a machine that has joined a domain must also be removed from that domain's directory, or its computer account will be stale.
