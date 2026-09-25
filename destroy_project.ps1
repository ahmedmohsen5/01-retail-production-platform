#Requires -Version 5.1
<#
Deletes the dev Terraform stack and all images in its ECR repositories.
Keeps source files, the bootstrap state bucket, and the shared OIDC provider.
#>
[CmdletBinding()]
param(
    [string]$BackendConfig = 'backend.hcl',
    [string]$ExpectedAccountId = '147723036683',
    [string]$Region = 'us-east-1'
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
Push-Location $PSScriptRoot
try {
    foreach ($tool in @('aws','terraform')) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "Install $tool first." }
    }
    $identity = Read-ToolJson aws @('sts','get-caller-identity','--output','json')
    if ($identity.Account -ne $ExpectedAccountId) { throw "Wrong AWS account: $($identity.Account); expected $ExpectedAccountId." }
    $tfDirectory = Join-Path $PSScriptRoot 'terraform/env/dev'
    $tf = "-chdir=$tfDirectory"
    Invoke-Tool terraform @($tf,'init','-input=false',"-backend-config=$BackendConfig")
    # This variable is required by the configuration but unused during destroy.
    # Pass a loopback CIDR so teardown also works without startup's generated file.
    $inputFile = Join-Path $tfDirectory 'destroy.inputs.tfvars.json'
    $inputs = @{ eks_public_access_cidrs = @('127.0.0.1/32'); aws_region = $Region } | ConvertTo-Json
    [IO.File]::WriteAllText($inputFile, $inputs, (New-Object Text.UTF8Encoding($false)))
    $planArgs = @($tf,'plan','-destroy','-input=false','-out=destroy.tfplan',"-var-file=$inputFile")
    Invoke-Tool terraform $planArgs
    $plan = Read-ToolJson terraform @($tf,'show','-json','destroy.tfplan')
    $changes = @()
    if ($plan.PSObject.Properties['resource_changes']) {
        $changes = @($plan.resource_changes | Where-Object { $_.mode -eq 'managed' -and $_.change.actions -contains 'delete' })
        $unexpected = @($plan.resource_changes | Where-Object { $_.change.actions -contains 'create' -or $_.change.actions -contains 'update' })
        if ($unexpected.Count) { throw 'Refusing a teardown plan that creates or updates resources.' }
    }
    Write-Host "Deleting dev infrastructure in account $ExpectedAccountId, region $Region, including ECR images."
    # Delete Kubernetes load balancer resources while their controller still runs.
    foreach ($cluster in @($changes | Where-Object { $_.type -eq 'aws_eks_cluster' })) {
        if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw 'Install kubectl to clean up Kubernetes load balancers before destroying EKS.' }
        $clusterName = $cluster.change.before.name
        $context = "retail-destroy-$ExpectedAccountId-$clusterName"
        Invoke-Tool aws @('eks','update-kubeconfig','--region',$Region,'--name',$clusterName,'--alias',$context)
        Invoke-Tool kubectl @('--context',$context,'-n','retail','delete','ingress,service','--all','--ignore-not-found=true','--wait=true','--timeout=10m')
        Invoke-Tool kubectl @('--context',$context,'delete','namespace','retail','--ignore-not-found=true','--wait=true','--timeout=10m')
    }
    foreach ($repository in @($changes | Where-Object { $_.type -eq 'aws_ecr_repository' })) {
        $before = $repository.change.before
        if ($before.arn -notlike "arn:aws:ecr:${Region}:${ExpectedAccountId}:repository/retail-*") {
            throw "ECR repository is outside the expected project/account/region: $($before.arn)"
        }
        # Only repositories present in the refreshed destroy plan are deleted.
        Invoke-Tool aws @('ecr','delete-repository','--region',$Region,'--registry-id',$ExpectedAccountId,'--repository-name',$before.name,'--force','--query','repository.repositoryName','--output','text')
    }
    # Refresh after direct ECR deletion so Terraform reconciles the missing resources.
    Invoke-Tool terraform $planArgs
    Invoke-Tool terraform @($tf,'apply','-input=false','destroy.tfplan')
    $remaining = @(Invoke-Tool terraform @($tf,'state','list'))
    if (@($remaining | Where-Object { $_.Trim() -ne '' }).Count) { throw 'Terraform state is not empty; inspect remaining resources before retrying.' }
    Write-Host 'Dev teardown complete. Source files, bootstrap backend, and shared OIDC provider retained.'
}
finally { Pop-Location }
