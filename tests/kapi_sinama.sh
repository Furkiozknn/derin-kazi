#!/usr/bin/env bash
# tests/kapi.sh'in kendi sinamasi. Godot gerektirmez; CI'da her push'ta kosar.
# Gunluk ornekleri gercek Godot 4.7.2 ciktisinin bicimini izler
# (25 Eylul 2026: 304 + 156 + 7 + 10 = 477 sinama; fay kapisi 12/12 tohum).
set -uo pipefail

kok="$(cd "$(dirname "$0")" && pwd)"
kapi="$kok/kapi.sh"
gecici="$(mktemp -d)"
trap 'rm -rf "$gecici"' EXIT
basarisiz=0

# $1 ad, $2 beklenen cikis (0 gecer / 1 duser), $3.. kapi.sh bayraklari + taban,
# stdin gunluk
bekle() {
  local ad="$1" beklenen="$2" dosya="$gecici/$1.log" kod
  shift 2
  cat >"$dosya"
  local arg=("$@")
  local taban="${arg[-1]}"
  unset 'arg[-1]'
  bash "$kapi" "${arg[@]}" "$dosya" "$taban" >/dev/null 2>&1
  kod=$?
  if [ "$kod" -eq "$beklenen" ]; then
    echo "  tamam  $ad (cikis $kod)"
  else
    echo "  HATA   $ad: beklenen $beklenen, gelen $kod"
    basarisiz=$((basarisiz + 1))
  fi
}

echo "[test kapisi]"

bekle temiz 0 304 <<'EOF2'
== Derin Kazı birim testleri ==
  [OK] 12 tohumun hepsinde çekirdeğe yol var (hepsi tamam)
== 304 sınama, 0 hata ==
WARNING: 5 ObjectDB instances were leaked at exit (run with `--verbose` for details).
ERROR: 3 resources still in use at exit (run with --verbose for details).
EOF2

bekle tabandan_fazla 0 156 <<'EOF2'
== Oynanış testi ==
== 170 sınama, 0 hata ==
EOF2

bekle kucuk_paket_temiz 0 7 <<'EOF2'
== Denge simülasyonu (kusursuz bot) ==
== 7 sınama, 0 hata ==
EOF2

bekle sinama_hatasi 1 10 <<'EOF2'
  [HATA] sisli insan botu çekirdeğe varıyor
== 10 sınama, 1 hata ==
EOF2

# Asil kapattigi aciklik: bir test fonksiyonu calisma zamani hatasiyla
# kesildi, kalan dogru() cagrilari sayilmadi, ama paket yine "0 hata" ile bitti.
bekle betik_hatasi_sessiz_atlama 1 304 <<'EOF2'
SCRIPT ERROR: Invalid access to property or key 'hucre' on a base object of type 'Nil'.
          at: _deprem_testleri (res://tests/test_calistir.gd:900)
== 281 sınama, 0 hata ==
EOF2

bekle betik_hatasi_sayi_tam 1 156 <<'EOF2'
SCRIPT ERROR: Invalid operands 'int' and 'bool' in operator '=='.
== 156 sınama, 0 hata ==
EOF2

bekle derleme_hatasi 1 304 <<'EOF2'
SCRIPT ERROR: Parse Error: Identifier "Ses" not declared in the current scope.
EOF2

bekle tabanin_alti 1 304 <<'EOF2'
== 300 sınama, 0 hata ==
EOF2

bekle sonuc_satiri_yok 1 156 <<'EOF2'
== Oynanış testi ==
  [OK] menü açılıyor
EOF2

bekle bos_gunluk 1 304 </dev/null

echo "[fay kapisi]"

bekle fay_temiz 0 --fay 12 <<'EOF2'
fay AÇIK   ->  BFS yol: 12/12 []  |  bot çekirdeğe vardı: 12/12 []
== fay açıkken kusursuz bot 12/12, sisli insan botu 12/12 tohumda çekirdeğe vardı — TAMAM ==
ERROR: 3 resources still in use at exit (run with --verbose for details).
EOF2

bekle fay_kaldi 1 --fay 12 <<'EOF2'
== fay açıkken kusursuz bot 12/12, sisli insan botu 11/12 tohumda çekirdeğe vardı — KALDI ==
EOF2

bekle fay_betik_hatasi 1 --fay 12 <<'EOF2'
SCRIPT ERROR: Invalid call. Nonexistent function 'kos' in base 'Nil'.
== fay açıkken kusursuz bot 12/12, sisli insan botu 12/12 tohumda çekirdeğe vardı — TAMAM ==
EOF2

bekle fay_tabanin_alti 1 --fay 12 <<'EOF2'
== fay açıkken kusursuz bot 8/8, sisli insan botu 8/8 tohumda çekirdeğe vardı — TAMAM ==
EOF2

bekle fay_satiri_yok 1 --fay 12 <<'EOF2'
fay KAPALI ->  BFS yol: 12/12 []  |  bot çekirdeğe vardı: 12/12 []
EOF2

if [ "$basarisiz" -ne 0 ]; then
  echo "=== test kapisi: $basarisiz sinama basarisiz ==="
  exit 1
fi
echo "=== test kapisi: tum sinamalar gecti ==="
