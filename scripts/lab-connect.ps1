<#
.SYNOPSIS
  Open a tunnel into the isolated SC-300 lab network and start Remote Desktop.

.DESCRIPTION
  The lab (10.12.41.0/24) exists only on sevro's sc300 bridge, so it cannot be reached
  directly from a home VLAN. This script opens an SSH tunnel through sevro that forwards
  one local port per lab VM, then launches Remote Desktop to the machine you ask for.
  Close Remote Desktop, then press Enter here to shut the tunnel down.

  Local ports:  dc01 -> 3390   ws01 -> 3391   ws02 -> 3392

.PARAMETER Target
  Which machine to open: dc01 (default), ws01, ws02, or all.

.PARAMETER ViaOps
  Hop through ops instead of connecting to sevro directly. Use this from a device whose
  key is authorized on ops only (the laptop).

.PARAMETER TunnelOnly
  Open the tunnel but do not launch Remote Desktop (use your own RDP client or WinRM).

.EXAMPLE
  .\lab-connect.ps1
  .\lab-connect.ps1 -Target ws01
  .\lab-connect.ps1 -Target all -ViaOps

.NOTES
  Needs the Windows OpenSSH client (ssh.exe). Remote Desktop only answers on dc01 until it
  is enabled on the Windows 11 clients. Sign in as Administrator (dc01) or labadmin (clients);
  the password is in ~/.config/sc300-lab/admin.pass on ops. Nothing secret is stored here.
#>
[CmdletBinding()]
param(
    [ValidateSet('dc01', 'ws01', 'ws02', 'all')][string]$Target = 'dc01',
    [switch]$ViaOps,
    [switch]$TunnelOnly
)

$ErrorActionPreference = 'Stop'

$SevroHost = 'sevro.demarzo.lab'
$OpsHost   = 'ops.demarzo.lab'
$User      = 'demarzo'
# name -> local port, lab address
$Machines = [ordered]@{
    dc01 = @{ Port = 3390; Ip = '10.12.41.2' }
    ws01 = @{ Port = 3391; Ip = '10.12.41.11' }
    ws02 = @{ Port = 3392; Ip = '10.12.41.12' }
}

if (-not (Get-Command ssh.exe -ErrorAction SilentlyContinue)) {
    throw 'ssh.exe not found. Install the "OpenSSH Client" optional feature in Windows Settings.'
}

$jump = if ($ViaOps) { $OpsHost } else { $SevroHost }

# Preflight: a hidden tunnel cannot answer a host-key or passphrase prompt, so fail early and say why.
Write-Host "Checking SSH access to $User@$jump ..."
# (Windows PowerShell 5.1 turns native stderr into an error under 'Stop', so relax it for this call.)
$ErrorActionPreference = 'Continue'
& ssh.exe -o BatchMode=yes -o ConnectTimeout=8 "$User@$jump" 'true' 2>$null
$loginOk = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = 'Stop'
if (-not $loginOk) {
    Write-Host ''
    Write-Host "Could not log in to $User@$jump without a prompt." -ForegroundColor Red
    Write-Host '  - First time? Run this once and accept the host key after checking its fingerprint:'
    Write-Host "      ssh $User@$jump"
    Write-Host '    (fingerprint on the host: ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub)'
    Write-Host '  - Key refused? Your key must be authorized there; the laptop key works with -ViaOps.'
    Write-Host '  - Key has a passphrase? Load it into ssh-agent first: ssh-add'
    exit 1
}

# Refuse to clash with something already listening on the local ports.
foreach ($m in $Machines.GetEnumerator()) {
    $busy = Get-NetTCPConnection -State Listen -LocalPort $m.Value.Port -ErrorAction SilentlyContinue
    if ($busy) { throw "Local port $($m.Value.Port) is already in use (an old tunnel still running?)." }
}

$common = @('-N', '-o', 'ExitOnForwardFailure=yes', '-o', 'ServerAliveInterval=30', '-o', 'BatchMode=yes')
$forwards = foreach ($m in $Machines.GetEnumerator()) { "-L $($m.Value.Port):$($m.Value.Ip):3389" }

if ($ViaOps) {
    # Hop 1 forwards the local ports to ops; the command it runs on ops opens hop 2 to sevro.
    $hop1 = foreach ($m in $Machines.GetEnumerator()) { '-L', "$($m.Value.Port):localhost:$($m.Value.Port)" }
    $remote = 'ssh -N ' + ($forwards -join ' ') + ' sevro'
    $sshArgs = $common + $hop1 + @("$User@$OpsHost", "`"$remote`"")
} else {
    $sshArgs = $common + ($forwards | ForEach-Object { $_ -split ' ' }) + @("$User@$SevroHost")
}

Write-Host 'Opening the tunnel ...'
$tunnel = Start-Process -FilePath ssh.exe -ArgumentList $sshArgs -WindowStyle Hidden -PassThru

try {
    # Wait until the first forwarded port accepts connections (up to 20 s).
    $port = $Machines['dc01'].Port
    $up = $false
    foreach ($i in 1..40) {
        if ($tunnel.HasExited) { throw "The tunnel exited early (code $($tunnel.ExitCode))." }
        $c = New-Object System.Net.Sockets.TcpClient
        try { $c.Connect('127.0.0.1', $port); $up = $true } catch { } finally { $c.Close() }
        if ($up) { break }
        Start-Sleep -Milliseconds 500
    }
    if (-not $up) { throw "The tunnel did not come up on local port $port." }
    if ($ViaOps) { Start-Sleep -Seconds 3 }   # hop 2 on ops needs a moment after hop 1 listens

    Write-Host ''
    Write-Host 'Tunnel is up:' -ForegroundColor Green
    foreach ($m in $Machines.GetEnumerator()) {
        Write-Host ("  {0}  localhost:{1}  ->  {2}:3389" -f $m.Key, $m.Value.Port, $m.Value.Ip)
    }

    if (-not $TunnelOnly) {
        $names = if ($Target -eq 'all') { @($Machines.Keys) } else { @($Target) }
        foreach ($n in $names) {
            Write-Host "Starting Remote Desktop to $n ..."
            Start-Process mstsc.exe -ArgumentList "/v:localhost:$($Machines[$n].Port)"
        }
        if ($Target -ne 'dc01' -and $Target -ne 'all') {
            Write-Host 'Note: Remote Desktop is off on the Windows 11 clients by default. Use the Proxmox console if it refuses.' -ForegroundColor Yellow
        }
    }

    Write-Host ''
    Read-Host 'Press Enter to close the tunnel'
}
finally {
    if ($tunnel -and -not $tunnel.HasExited) {
        Stop-Process -Id $tunnel.Id -Force
        Write-Host 'Tunnel closed.'
    }
}
