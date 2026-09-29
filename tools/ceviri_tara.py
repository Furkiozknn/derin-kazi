"""Koddaki ve sahnelerdeki Turkce arayuz anahtarlarini listeler; EN tablosunda
olmayanlari isaretler. Kullanim (depo kokunden):  python tools/ceviri_tara.py
Cikis kodu: eksik varsa 1. (tests/test_calistir.gd -> _ceviri_testleri ayni
kontrolu oyunun icinden yapar; bu arac yeni metin eklerken listeyi cikarir.)"""
import glob
import io
import re
import sys

R_KOD = re.compile(r'(?<![A-Za-z_])(?:Ceviri\.t|tr)\(\s*"((?:[^"\\]|\\.)*)"')
R_SAHNE = re.compile(r'^(?:text|placeholder_text) = "((?:[^"\\]|\\.)*)"', re.M)


def coz(s):
    return s.replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")


def anahtarlar():
    out = []
    for f in sorted(glob.glob("scripts/*.gd")):
        if f.endswith(("ceviri.gd", "ceviri_en.gd")):
            continue
        t = io.open(f, encoding="utf-8").read()
        out += [(f, coz(m.group(1))) for m in R_KOD.finditer(t)]
    for f in sorted(glob.glob("scenes/*.tscn")):
        if f.endswith("kapak.tscn"):
            continue
        t = io.open(f, encoding="utf-8").read()
        out += [(f, coz(m.group(1))) for m in R_SAHNE.finditer(t) if m.group(1) not in ("...", "")]
    return out


def en_tablosu():
    t = io.open("scripts/ceviri_en.gd", encoding="utf-8").read()
    return set(coz(m.group(1)) for m in re.finditer(r'^\t"((?:[^"\\]|\\.)*)":', t, re.M))


if __name__ == "__main__":
    en = en_tablosu()
    gorulen = set()
    eksik = 0
    for f, k in anahtarlar():
        if k in gorulen:
            continue
        gorulen.add(k)
        if k not in en and re.search(r"[A-Za-zığşçöüİĞŞÇÖÜ]{3,}", k):
            print("EKSIK %-22s %r" % (f.split("/")[-1], k))
            eksik += 1
    print("%d anahtar, %d eksik" % (len(gorulen), eksik))
    sys.exit(1 if eksik else 0)
