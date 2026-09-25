#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Repository = 'ahmedmohsen5/01-retail-production-platform',
    [string]$BackendConfig = 'backend.hcl',
    [string]$PublicIp,
    [ValidateRange(1,180)][int]$BuildTimeoutMinutes = 60,
    [string]$RolloutTimeout = '10m'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
function Invoke-Tool {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed (exit $LASTEXITCODE): $($Arguments -join ' ')" }
}
function Read-ToolJson {
    param([string]$Command, [string[]]$Arguments)
    $raw = Invoke-Tool $Command $Arguments
    ($raw -join "`n") | ConvertFrom-Json
}
function Write-Utf8 {
    param([string]$Path, [string]$Content)
    [IO.File]::WriteAllText($Path, $Content, (New-Object Text.UTF8Encoding($false)))
}
Push-Location $PSScriptRoot
try {
    foreach ($tool in @('aws','terraform','gh','kubectl')) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "Install $tool and add it to PATH first." }
    }
    Invoke-Tool gh @('auth','status')
    $identity = Read-ToolJson aws @('sts','get-caller-identity','--output','json')
    # Existing OIDC trust allows main only. Check the remote workflow before creating infrastructure.
    $workflow = 'aws-identity-test.yml'
    $remote = Invoke-Tool gh @('api',"repos/$Repository/contents/.github/workflows/${workflow}?ref=main",'-H','Accept: application/vnd.github.raw+json')
    if (($remote -join "`n") -notmatch 'startup_id:') { throw 'Commit and push the updated workflow to main before running this script.' }
    if (-not $PublicIp) { $PublicIp = (Invoke-RestMethod 'https://checkip.amazonaws.com' -TimeoutSec 20).Trim() }
    $parsedIp = $null
    if (-not [Net.IPAddress]::TryParse($PublicIp,[ref]$parsedIp) -or $parsedIp.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
        throw "Expected an IPv4 address; received '$PublicIp'."
    }
    $tfDirectory = Join-Path $PSScriptRoot 'terraform/env/dev'
    Write-Utf8 (Join-Path $tfDirectory 'startup.auto.tfvars.json') (@{eks_public_access_cidrs = @("$PublicIp/32")} | ConvertTo-Json)
    Write-Host "Allowing EKS API access from $PublicIp/32. Applying dev infrastructure."
    $tf = "-chdir=$tfDirectory"
    Invoke-Tool terraform @($tf,'init','-input=false',"-backend-config=$BackendConfig")
    Invoke-Tool terraform @($tf,'validate')
    Invoke-Tool terraform @($tf,'plan','-input=false','-out=startup.tfplan')
    Invoke-Tool terraform @($tf,'apply','-input=false','-auto-approve','startup.tfplan')
    $outputs = Read-ToolJson terraform @($tf,'output','-json')
    $region = $outputs.aws_region.value
    $cluster = $outputs.cluster_name.value
    foreach ($entry in @{AWS_ROLE_ARN=$outputs.github_actions_role_arn.value; AWS_ACCOUNT_ID=$identity.Account; AWS_REGION=$region}.GetEnumerator()) {
        Invoke-Tool gh @('variable','set',$entry.Key,'--body',$entry.Value,'--repo',$Repository)
    }
    $startupId = 'startup-' + [guid]::NewGuid().ToString('N')
    Invoke-Tool gh @('workflow','run',$workflow,'--repo',$Repository,'--ref','main','-f',"startup_id=$startupId")
    $deadline = (Get-Date).AddMinutes($BuildTimeoutMinutes)
    $run = $null
    do {
        $runs = @(Read-ToolJson gh @('run','list','--repo',$Repository,'--workflow',$workflow,'--branch','main','--event','workflow_dispatch','--limit','100','--json','databaseId,displayTitle,status,conclusion,headSha,attempt,url'))
        $run = $runs | Where-Object { $_.displayTitle -eq $startupId } | Select-Object -First 1
        if ($run -and $run.status -eq 'completed') { break }
        if ((Get-Date) -ge $deadline) { throw "Build wait timed out. Check Actions for $startupId; the run has not been cancelled." }
        Write-Host "Waiting for image publish ($startupId)..."
        Start-Sleep -Seconds 15
    } while ($true)
    if ($run.conclusion -ne 'success') { throw "Image build ended with $($run.conclusion): $($run.url)" }
    $tag = "$($run.headSha)-$($run.databaseId)-$($run.attempt)"
    $services = @('catalog','cart','orders','checkout','ui')
    $updates = @{}
    foreach ($service in $services) {
        $repoName = "retail-$service"
        $uri = $outputs.ecr_repository_urls.value.PSObject.Properties[$repoName].Value
        # Verify all exact image tags before changing any manifests.
        Invoke-Tool aws @('ecr','describe-images','--region',$region,'--repository-name',$repoName,'--image-ids',"imageTag=$tag",'--query','imageDetails[0].imageDigest','--output','text')
        $path = Join-Path $PSScriptRoot "k8s/workloads/$service/deployment.yaml"
        $yaml = [IO.File]::ReadAllText($path)
        $pattern = '(?m)^(\s*image:\s*)[^\r\n]+'
        if ([regex]::Matches($yaml,$pattern).Count -ne 1) { throw "Expected exactly one container image in $path." }
        $updates[$path] = [regex]::Replace($yaml,$pattern,"`${1}${uri}:$tag")
    }
    foreach ($entry in $updates.GetEnumerator()) { Write-Utf8 $entry.Key $entry.Value }
    $context = "retail-startup-$($identity.Account)-$cluster"
    Invoke-Tool aws @('eks','update-kubeconfig','--region',$region,'--name',$cluster,'--alias',$context)
    Invoke-Tool kubectl @('--context',$context,'apply','-f','k8s/base/namespace.yml')
    Invoke-Tool kubectl @('--context',$context,'apply','-R','-f','k8s/base')
    Invoke-Tool kubectl @('--context',$context,'apply','-R','-f','k8s/workloads')
    foreach ($service in $services) {
        Invoke-Tool kubectl @('--context',$context,'-n','retail','rollout','status',"deployment/$service","--timeout=$RolloutTimeout")
    }
    Invoke-Tool kubectl @('--context',$context,'-n','retail','get','pods,services')
    Write-Host "Project started successfully. Published image tag: $tag"
}
finally { Pop-Location }
