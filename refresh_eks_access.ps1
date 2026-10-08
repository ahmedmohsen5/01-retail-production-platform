#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ClusterName = 'retail-platform-dev',
    [string]$Region = 'us-east-1',
    [ValidateRange(1,30)][int]$TimeoutMinutes = 10
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
function Invoke-AwsJson {
    param([string[]]$Arguments)
    $raw = & aws @Arguments --region $Region --output json --no-cli-pager
    if ($LASTEXITCODE -ne 0) { throw "AWS command failed: $($Arguments -join ' ')" }
    return (($raw -join "`n") | ConvertFrom-Json)
}
foreach ($tool in @('aws','kubectl')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "$tool must be installed and on PATH." }
}
$ip = (Invoke-RestMethod https://checkip.amazonaws.com -TimeoutSec 20).Trim()
$parsed = $null
if (-not [Net.IPAddress]::TryParse($ip,[ref]$parsed) -or $parsed.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
    throw "Invalid public IPv4 address: $ip"
}
$cidr = "$ip/32"
$cluster = (Invoke-AwsJson @('eks','describe-cluster','--name',$ClusterName)).cluster
if (-not $cluster.resourcesVpcConfig.endpointPublicAccess) {
    throw 'Public API access is disabled. Enable it through Terraform or use a VPC connection.'
}
# This dev environment intentionally allows only the current workstation IP.
# Update the matching Terraform input too, so the next apply preserves access.
$inputPath = Join-Path $PSScriptRoot 'terraform/env/dev/startup.auto.tfvars.json'
$inputs = if (Test-Path $inputPath) { Get-Content $inputPath -Raw | ConvertFrom-Json } else { [pscustomobject]@{} }
$inputs | Add-Member -NotePropertyName eks_public_access_cidrs -NotePropertyValue @($cidr) -Force
$allowed = @($cluster.resourcesVpcConfig.publicAccessCidrs)
if ($allowed.Count -ne 1 -or $allowed[0] -ne $cidr) {
    Write-Host "Refreshing $ClusterName public API allowlist to $cidr"
    $update = Invoke-AwsJson @('eks','update-cluster-config','--name',$ClusterName,'--resources-vpc-config',"publicAccessCidrs=$cidr")
    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    do {
        $result = (Invoke-AwsJson @('eks','describe-update','--name',$ClusterName,'--update-id',$update.update.id)).update
        if ($result.status -eq 'Successful') { break }
        if ($result.status -in @('Failed','Cancelled')) { throw ($result | ConvertTo-Json -Depth 10) }
        if ((Get-Date) -ge $deadline) { throw "Timed out waiting for update $($update.update.id). Check its status before retrying." }
        Write-Host 'Waiting for EKS endpoint update...'
        Start-Sleep -Seconds 10
    } while ($true)
}
[IO.File]::WriteAllText($inputPath, ($inputs | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
$context = "retail-access-$ClusterName"
& aws eks update-kubeconfig --region $Region --name $ClusterName --alias $context
if ($LASTEXITCODE -ne 0) { throw 'Kubeconfig update failed.' }
& kubectl --context $context get nodes --request-timeout=30s
if ($LASTEXITCODE -ne 0) { throw 'Allowlist updated, but Kubernetes access failed. Check VPN, DNS, and cluster permissions.' }
Write-Host "Access ready for $cidr. Terraform input updated; no Terraform apply needed."
