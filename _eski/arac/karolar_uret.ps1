# Karo atlasini uretir: assets/sprites/karolar.png (144x16, 9 adet 16x16 karo)
# Yer tutucu grafik. Gercek pixel art sonraki asamada Pixelorama ile yapilacak.
# Calistir: powershell -ExecutionPolicy Bypass -File arac\karolar_uret.ps1
Add-Type -AssemblyName System.Drawing

$kok = Split-Path -Parent $PSScriptRoot
$hedef = Join-Path $kok 'assets\sprites\karolar.png'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $hedef) | Out-Null

$K = 16
# sira: toprak, tas, sert tas, bakir, demir, altin, elmas, kaya, cekirdek
$karolar = @(
  @{ zemin = @(122, 78, 44);  benek = @(96, 58, 32);   parlak = @(150, 100, 58); maden = $null },
  @{ zemin = @(108, 108, 120); benek = @(86, 86, 98);   parlak = @(128, 128, 140); maden = $null },
  @{ zemin = @(66, 66, 78);   benek = @(48, 48, 60);   parlak = @(86, 86, 98);   maden = $null },
  @{ zemin = @(104, 76, 56);  benek = @(84, 60, 44);   parlak = @(120, 90, 66);  maden = @(222, 126, 54) },
  @{ zemin = @(98, 98, 110);  benek = @(78, 78, 90);   parlak = @(114, 114, 126); maden = @(208, 214, 226) },
  @{ zemin = @(80, 78, 88);   benek = @(62, 60, 70);   parlak = @(94, 92, 102);  maden = @(244, 198, 48) },
  @{ zemin = @(58, 58, 74);   benek = @(44, 44, 58);   parlak = @(72, 72, 88);   maden = @(96, 228, 228) },
  @{ zemin = @(28, 28, 34);   benek = @(20, 20, 26);   parlak = @(46, 46, 54);   maden = $null },
  @{ zemin = @(120, 24, 96);  benek = @(90, 16, 72);   parlak = @(180, 50, 140); maden = @(255, 232, 250) }
)

# Maden damarlari: her karo icin ayni yerlerde, deterministik.
$damar = @(
  @(3, 4), @(4, 3), @(4, 4), @(3, 5),
  @(10, 6), @(11, 6), @(11, 7), @(10, 7), @(12, 7),
  @(6, 11), @(7, 11), @(7, 12), @(6, 12), @(8, 12)
)

$bmp = New-Object System.Drawing.Bitmap(($K * $karolar.Count), $K)
$rnd = New-Object System.Random(20260916)

for ($i = 0; $i -lt $karolar.Count; $i++) {
  $t = $karolar[$i]
  $zemin  = [System.Drawing.Color]::FromArgb($t.zemin[0],  $t.zemin[1],  $t.zemin[2])
  $benek  = [System.Drawing.Color]::FromArgb($t.benek[0],  $t.benek[1],  $t.benek[2])
  $parlak = [System.Drawing.Color]::FromArgb($t.parlak[0], $t.parlak[1], $t.parlak[2])
  for ($y = 0; $y -lt $K; $y++) {
    for ($x = 0; $x -lt $K; $x++) {
      $c = $zemin
      $r = $rnd.Next(100)
      if ($r -lt 14) { $c = $benek } elseif ($r -lt 24) { $c = $parlak }
      # ust kenar biraz aydinlik, alt kenar koyu: karolar yandan bakinca ayrisiyor
      if ($y -eq 0) { $c = $parlak }
      if ($y -eq ($K - 1)) { $c = $benek }
      $bmp.SetPixel(($i * $K + $x), $y, $c)
    }
  }
  if ($null -ne $t.maden) {
    $m  = [System.Drawing.Color]::FromArgb($t.maden[0], $t.maden[1], $t.maden[2])
    $mk = [System.Drawing.Color]::FromArgb([int]($t.maden[0] * 0.65), [int]($t.maden[1] * 0.65), [int]($t.maden[2] * 0.65))
    foreach ($p in $damar) {
      $bmp.SetPixel(($i * $K + $p[0]), $p[1], $m)
      if ($p[1] + 1 -lt $K) { $bmp.SetPixel(($i * $K + $p[0]), ($p[1] + 1), $mk) }
    }
  }
}

$bmp.Save($hedef, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Output "yazildi: $hedef ($($bmp.Width)x$($bmp.Height))"
$bmp.Dispose()
