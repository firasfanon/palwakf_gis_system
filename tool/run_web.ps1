# tool/run_web.ps1
# تشغيل Flutter Web مع تمرير مفاتيح Supabase من ملف .env بدون كتابتها في الأوامر.
# الاستخدام:
#   powershell -ExecutionPolicy Bypass -File tool\run_web.ps1
# أو (داخل PowerShell):
#   .\tool\run_web.ps1

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root ".env"

if (!(Test-Path $envFile)) {
  Write-Host "❌ ملف .env غير موجود في جذر المشروع: $envFile" -ForegroundColor Red
  Write-Host "أنشئ ملف .env وضع فيه:" -ForegroundColor Yellow
  Write-Host "SUPABASE_URL=..." -ForegroundColor Yellow
  Write-Host "SUPABASE_ANON_KEY=..." -ForegroundColor Yellow
  exit 1
}

# قراءة .env
$vars = @{}
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if ($line.Length -eq 0) { return }
  if ($line.StartsWith("#")) { return }

  $parts = $line.Split("=", 2)
  if ($parts.Length -ne 2) { return }

  $name = $parts[0].Trim()
  $value = $parts[1].Trim()

  # إزالة علامات اقتباس إن وجدت
  if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
    $value = $value.Substring(1, $value.Length - 2)
  }

  $vars[$name] = $value
}

if (-not $vars.ContainsKey("SUPABASE_URL") -or [string]::IsNullOrWhiteSpace($vars["SUPABASE_URL"])) {
  Write-Host "❌ SUPABASE_URL غير موجود/فارغ في .env" -ForegroundColor Red
  exit 1
}
if (-not $vars.ContainsKey("SUPABASE_ANON_KEY") -or [string]::IsNullOrWhiteSpace($vars["SUPABASE_ANON_KEY"])) {
  Write-Host "❌ SUPABASE_ANON_KEY غير موجود/فارغ في .env" -ForegroundColor Red
  exit 1
}

Write-Host "✅ تشغيل Flutter Web مع Supabase من .env (بدون طباعة المفاتيح)..." -ForegroundColor Green

Set-Location $root
flutter pub get | Out-Null

flutter run -d chrome `
  --dart-define=SUPABASE_URL=$($vars["SUPABASE_URL"]) `
  --dart-define=SUPABASE_ANON_KEY=$($vars["SUPABASE_ANON_KEY"])
