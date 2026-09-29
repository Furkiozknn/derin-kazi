# Godot kilidi + tek noktadan Godot calistirma. Dot-source ederek kullanilir:
#   . "$PSScriptRoot\..\tools\kilit.ps1"
#   $kod = Godot-Calistir @('--headless','--path',$kok,'--import') $log
#
# Neden: depolarin ortak ust klasorundeki .godot-kilit uzerinden ayni anda tek Godot calisir
# (3 oyun oturumu paralel, RAM dar). Godot'u yuvalanmis Start-Process ile
# cagirmak stdout yonlendirmesini yutuyor - bu yuzden tek seviye.

# Varsayilan gelistirme makinesinin yolu; baska makinede GODOT_KILIT ile ez.
$script:KILIT = if ($env:GODOT_KILIT) { $env:GODOT_KILIT } else { Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) '.godot-kilit' }
# PATH'te godot varsa onu kullan; yoksa winget kurulumunun varsayilan yoluna dus.
$script:GODOT = (Get-Command godot -ErrorAction SilentlyContinue).Source
if (-not $script:GODOT) { $script:GODOT = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\godot.exe' }
$script:SLUG  = 'derin-kazi'

function Kilit-Al {
  for ($i = 0; $i -lt 40; $i++) {
    if (Test-Path $script:KILIT) {
      $yas = (Get-Date) - (Get-Item $script:KILIT).LastWriteTime
      $sahip = (Get-Content $script:KILIT -ErrorAction SilentlyContinue | Select-Object -First 1)
      # NOT: burada YALNIZ sayiliyor. Godot sureci OLDURULMEZ - baska oyun
      # oturumlarinin (kanca, yercekimi-cevir, tek-tus-kosu) kosusunu
      # kesmek yok. Kendi surecimiz Godot-Calistir icinde PID ile oldurulur.
      $godotVar = @(Get-Process -Name 'Godot*' -ErrorAction SilentlyContinue).Count -gt 0
      if ($sahip -eq $script:SLUG -and -not $godotVar) {
        # Kendi oldurulmus isimizden kalan kilit: Godot calismiyorsa hemen devral.
        Write-Host 'kilit: kendi bayat kilidimiz, devraliniyor'
      } elseif ($yas.TotalMinutes -lt 15) {
        Start-Sleep -Seconds 30
        continue
      } else {
        Write-Host ("kilit: bayat ({0} dk), devraliniyor" -f [int]$yas.TotalMinutes)
      }
    }
    break
  }
  Set-Content -Path $script:KILIT -Value $script:SLUG -Encoding ascii
}

function Kilit-Birak {
  if (Test-Path $script:KILIT) { Remove-Item $script:KILIT -Force -ErrorAction SilentlyContinue }
}

# Godot'u kilitle calistirir. $Log verilirse stdout+stderr oraya yazilir.
# $ZamanAsimi saniye icinde bitmezse sureci (ve cocuklarini) oldurup 99 doner.
function Godot-Calistir {
  param([string[]] $ArgListe, [string] $Log = $null, [int] $ZamanAsimi = 600,
        [switch] $KilitDisarda)
  if (-not $KilitDisarda) { Kilit-Al }
  try {
    $ek = @{}
    if ($Log) {
      $ek['RedirectStandardOutput'] = $Log
      $ek['RedirectStandardError'] = "$Log.err"
    }
    $p = Start-Process -FilePath $script:GODOT -NoNewWindow -PassThru -ArgumentList $ArgListe @ek
    if (-not $p.WaitForExit($ZamanAsimi * 1000)) {
      & taskkill /PID $($p.Id) /T /F 2>&1 | Out-Null
      Write-Host "ZAMAN ASIMI ($ZamanAsimi sn)"
      return 99
    }
    # WaitForExit(ms) ExitCode'u doldurmuyor; parametresiz cagri gerekiyor.
    $p.WaitForExit()
    return $p.ExitCode
  } finally {
    if (-not $KilitDisarda) { Kilit-Birak }
  }
}
