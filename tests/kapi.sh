#!/usr/bin/env bash
# Test kapisi: test betiklerinin cikis kodu tek basina yeterli bir sinyal degil.
#
#   tests/kapi.sh <test-gunlugu> <en-az-sinama>      # test_calistir / test_oynanis /
#                                                    # test_denge / test_insan
#   tests/kapi.sh --fay <fay-gunlugu> <en-az-tohum>  # test_fay_olcum (bot kapisi)
#
# Test betikleri `quit(1 if _hata > 0 else 0)` ile cikiyor. Oysa GDScript'te
# bir calisma zamani hatasi (null erisimi, int == bool, eksik metot) yalnizca
# o fonksiyonu keser: motor "SCRIPT ERROR" yazar, fonksiyonun kalan
# dogru() cagrilari hic sayilmaz ve paket yine "== N sınama, 0 hata ==" ile
# 0 dondurur. Yani bir test bolumu sessizce yarida kalabilir ve CI yesil
# kalir. Fay olcumunde de ayni: bir olcum fonksiyonu kesilirse sayaclar
# yanlis kalir ama satir yine basilir.
#
# Test kipi gunlugu okuyup uc seyi zorunlu kilar:
#   1. "== N sınama, H hata ==" satiri var (paket sonuna kadar kostu), H == 0,
#   2. N >= en-az-sinama (ci.yml -> TEST_TABANI_*; sayi bilinen tabanin
#      altina dusmedi),
#   3. gunlukte "SCRIPT ERROR" / "Parse Error" yok.
# Fay kipi: "== fay açıkken kusursuz bot A/T, sisli insan botu B/T tohumda
# ... TAMAM ==" satiri var, A == B == T, T >= en-az-tohum, betik hatasi yok.
#
# Motorun cikista yazdigi "ERROR: N resources still in use at exit" satiri
# test sonucuyla ilgili degil; onu bilerek aramiyoruz.
#
# Sinamasi: tests/kapi_sinama.sh (Godot gerektirmez).
set -euo pipefail
export LC_ALL=C

kip=test
if [ "${1:-}" = "--fay" ]; then
  kip=fay
  shift
fi
if [ "$#" -ne 2 ]; then
  echo "kullanim: $0 [--fay] <gunluk> <en-az>" >&2
  exit 2
fi
gunluk="$1"
alt_sinir="$2"

if [ ! -r "$gunluk" ]; then
  echo "KAPI: gunluk okunamadi: $gunluk" >&2
  exit 1
fi

if grep -anE 'SCRIPT ERROR|Parse Error' "$gunluk" >&2; then
  echo "KAPI: gunlukte betik hatasi var (yukarida). Bir bolum yarida kesilmis olabilir." >&2
  exit 1
fi

if [ "$kip" = fay ]; then
  desen='^== fay açıkken kusursuz bot ([0-9]+)/([0-9]+), sisli insan botu ([0-9]+)/([0-9]+) tohumda .* TAMAM ==$'
  satir="$(grep -aE "$desen" "$gunluk" | tail -n 1 || true)"
  if [ -z "$satir" ]; then
    echo "KAPI: '== fay açıkken ... TAMAM ==' satiri yok; fay kapisi gecmedi ya da sonuna kadar kosmadi." >&2
    exit 1
  fi
  bot="$(sed -E "s#$desen#\1#" <<<"$satir")"
  toplam="$(sed -E "s#$desen#\2#" <<<"$satir")"
  sisli="$(sed -E "s#$desen#\3#" <<<"$satir")"
  toplam2="$(sed -E "s#$desen#\4#" <<<"$satir")"
  if [ "$bot" -ne "$toplam" ] || [ "$sisli" -ne "$toplam2" ] || [ "$toplam" -ne "$toplam2" ]; then
    echo "KAPI: fay acikken bot $bot/$toplam, sisli insan botu $sisli/$toplam2." >&2
    exit 1
  fi
  if [ "$toplam" -lt "$alt_sinir" ]; then
    echo "KAPI: fay olcumu $toplam tohum, taban $alt_sinir." >&2
    exit 1
  fi
  echo "KAPI: fay acikken bot $bot/$toplam, sisli insan botu $sisli/$toplam2 (taban $alt_sinir), betik hatasi yok."
  exit 0
fi

desen='^== ([0-9]+) sınama, ([0-9]+) hata ==$'
sonuc="$(grep -aE "$desen" "$gunluk" | tail -n 1 || true)"
if [ -z "$sonuc" ]; then
  echo "KAPI: '== N sınama, H hata ==' satiri yok; paket sonuna kadar kosmadi." >&2
  exit 1
fi

sayi="$(sed -E "s#$desen#\1#" <<<"$sonuc")"
hata="$(sed -E "s#$desen#\2#" <<<"$sonuc")"

if [ "$hata" -ne 0 ]; then
  echo "KAPI: $hata sinama basarisiz." >&2
  exit 1
fi
if [ "$sayi" -lt "$alt_sinir" ]; then
  echo "KAPI: $sayi sinama, taban $alt_sinir. Bir bolum atlanmis ya da yarida kalmis." >&2
  exit 1
fi

echo "KAPI: $sayi sinama (taban $alt_sinir), 0 hata, betik hatasi yok."
