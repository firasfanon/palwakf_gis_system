# tool/run_web.ps1
# Run Flutter Web with Supabase configuration from local environment or .env.
# This script never prints Supabase values.

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$EnvFile = Join-Path $Root ".env"

function Read-LocalEnvFile {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Path
  )

  $Result = @{}

  if (!(Test-Path -LiteralPath $Path)) {
    return $Result
  }

  Get-Content -LiteralPath $Path | ForEach-Object {
    $Line = $_.Trim()

    if ([string]::IsNullOrWhiteSpace($Line)) {
      return
    }

    if ($Line.StartsWith("#")) {
      return
    }

    $Parts = $Line.Split("=", 2)

    if ($Parts.Length -ne 2) {
      return
    }

    $Name = $Parts[0].Trim()
    $Value = $Parts[1].Trim()

    if (
      ($Value.StartsWith('"') -and $Value.EndsWith('"')) -or
      ($Value.StartsWith("'") -and $Value.EndsWith("'"))
    ) {
      $Value = $Value.Substring(1, $Value.Length - 2)
    }

    $Result[$Name] = $Value
  }

  return $Result
}

$LocalVars = Read-LocalEnvFile -Path $EnvFile

if ([string]::IsNullOrWhiteSpace($env:SUPABASE_URL) -and $LocalVars.ContainsKey("SUPABASE_URL")) {
  $env:SUPABASE_URL = $LocalVars["SUPABASE_URL"]
}

if ([string]::IsNullOrWhiteSpace($env:SUPABASE_ANON_KEY) -and $LocalVars.ContainsKey("SUPABASE_ANON_KEY")) {
  $env:SUPABASE_ANON_KEY = $LocalVars["SUPABASE_ANON_KEY"]
}

if ([string]::IsNullOrWhiteSpace($env:SUPABASE_URL)) {
  throw "SUPABASE_URL must be set in local environment or .env."
}

if ([string]::IsNullOrWhiteSpace($env:SUPABASE_ANON_KEY)) {
  throw "SUPABASE_ANON_KEY must be set in local environment or .env."
}

Write-Host "Running Flutter Web with local Supabase configuration. Values are not printed." -ForegroundColor Green

Set-Location $Root
flutter pub get | Out-Null

flutter run -d chrome `
  --dart-define=SUPABASE_URL="$env:SUPABASE_URL" `
  --dart-define=SUPABASE_ANON_KEY="$env:SUPABASE_ANON_KEY"
