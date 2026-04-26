param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,

    [ValidateSet("lyra_pickup_drop", "weapon_alignment", "building_visual", "sandbox_terrain", "other")]
    [string]$EvidenceType = "other",

    [string]$Scene = "",
    [string]$Claim = "",
    [string]$Notes = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$resolvedSource = Resolve-Path -LiteralPath $SourcePath
$sourceItem = Get-Item -LiteralPath $resolvedSource
if ($sourceItem.PSIsContainer) {
    throw "Visual evidence source must be a file, not a directory."
}

$allowedExtensions = @(".png", ".jpg", ".jpeg", ".webp", ".mp4", ".webm")
if ($sourceItem.Extension.ToLowerInvariant() -notin $allowedExtensions) {
    throw "Visual evidence must be an image or video file: .png, .jpg, .jpeg, .webp, .mp4, or .webm"
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$safeType = $EvidenceType -replace "[^a-zA-Z0-9_-]", "_"
$evidenceDir = Join-Path "logs/visual_evidence" "$($stamp)_$safeType"
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

$targetName = "evidence$($sourceItem.Extension.ToLowerInvariant())"
$targetPath = Join-Path $evidenceDir $targetName
Copy-Item -LiteralPath $sourceItem.FullName -Destination $targetPath -Force

$createdUtc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
$manifest = [PSCustomObject]@{
    schema_version = 1
    created_utc = $createdUtc
    evidence_type = $EvidenceType
    scene = $Scene
    claim = $Claim
    notes = $Notes
    source_path = $sourceItem.FullName
    evidence_path = $targetPath
}

$manifestPath = Join-Path $evidenceDir "manifest.json"
$manifest | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath -Encoding UTF8

Write-Host "Registered visual evidence: $manifestPath"
